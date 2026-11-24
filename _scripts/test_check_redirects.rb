require "fileutils"
require "minitest/autorun"
require "open3"
require "tmpdir"

class CheckRedirectsTest < Minitest::Test
  SCRIPT = File.expand_path("check_redirects.rb", __dir__)

  def with_site(files)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "_config.yml"), <<~YAML)
        defaults:
          - scope:
              path: ""
            values:
              layout: redirect
      YAML
      files.each do |path, content|
        file = File.join(dir, path)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, content)
      end
      yield Open3.capture3("ruby", SCRIPT, dir)
    end
  end

  def test_valid_redirect_and_non_redirect_page
    with_site("alias.md" => "---\nredir_to: 'https://example.com/'\n---\n",
              "404.html" => "---\nlayout: null\n---\n") do |_, stderr, status|
      assert status.success?, stderr
    end
  end

  def test_missing_and_blank_targets_fail
    with_site("missing.md" => "---\n---\n",
              "blank.md" => "---\nredir_to: '  '\n---\n") do |_, stderr, status|
      refute status.success?
      assert_includes stderr, "missing.md"
      assert_includes stderr, "blank.md"
    end
  end

  def test_non_string_target_fails
    with_site("invalid.md" => "---\nredir_to: 123\n---\n") do |_, stderr, status|
      refute status.success?
      assert_includes stderr, "invalid.md"
    end
  end

  def test_redirect_posts_are_checked
    with_site("_posts/2024-01-01-example.md" => "---\nlayout: redirect\n---\n") do |_, stderr, status|
      refute status.success?
      assert_includes stderr, "2024-01-01-example.md"
    end
  end
end
