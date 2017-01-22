# -*- encoding: utf-8 -*-
# frozen_string_literal: true
#
# Copyright (c) 2016 Mark Lee and contributors
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
# OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'fileutils'
require 'rbconfig'
require 'tomlrb'

module Thermite
  #
  # Configuration helper
  #
  class Config
    #
    # Creates a new configuration object.
    #
    # `options` is the same as the `Thermite::Tasks.new` parameter.
    #
    def initialize(options = {})
      @options = options
    end

    #
    # Location to emit debug output, if not `nil`. Defaults to `nil`.
    #
    def debug_filename
      @debug_filename ||= ENV['THERMITE_DEBUG_FILENAME']
    end

    #
    # The file extension of the compiled shared Rust library.
    #
    def shared_ext
      @shared_ext ||= begin
        if dlext == 'bundle'
          'dylib'
        elsif Gem.win_platform?
          'dll'
        else
          dlext
        end
      end
    end

    #
    # The interpolation-formatted string used to construct the download URI for the pre-built
    # native extension. Can be set via the `THERMITE_BINARY_URI_FORMAT` environment variable, or a
    # `binary_uri_format` option.
    #
    def binary_uri_format
      @binary_uri_format ||= ENV['THERMITE_BINARY_URI_FORMAT'] ||
                             @options[:binary_uri_format] ||
                             false
    end

    #
    # The major and minor version of the Ruby interpreter that's currently running.
    #
    def ruby_version
      @ruby_version ||= begin
        version_info = rbconfig_ruby_version.split('.')
        "ruby#{version_info[0]}#{version_info[1]}"
      end
    end

    # :nocov:

    #
    # Alias for `RbConfig::CONFIG['target_cpu']`.
    #
    def target_arch
      @target_arch ||= RbConfig::CONFIG['target_cpu']
    end

    #
    # Alias for `RbConfig::CONFIG['target_os']`.
    #
    def target_os
      @target_os ||= RbConfig::CONFIG['target_os']
    end
    # :nocov:

    #
    # The name of the library compiled by Rust.
    #
    # Due to the way that Cargo works, all hyphens in library names are replaced with underscores.
    #
    def library_name
      @library_name ||= begin
        base = toml[:lib] && toml[:lib][:name] ? toml[:lib] : toml[:package]
        base[:name].tr('-', '_') if base[:name]
      end
    end

    #
    # The basename of the Rust shared library.
    #
    def shared_library
      @shared_library ||= begin
        filename = "#{library_name}.#{shared_ext}"
        filename = "lib#{filename}" unless Gem.win_platform?
        filename
      end
    end

    #
    # Return the basename of the tarball generated by the `thermite:tarball` Rake task, given a
    # package `version`.
    #
    def tarball_filename(version)
      "#{library_name}-#{version}-#{ruby_version}-#{target_os}-#{target_arch}.tar.gz"
    end

    #
    # The top-level directory of the Ruby project. Defaults to the current working directory.
    #
    def ruby_toplevel_dir
      @ruby_toplevel_dir ||= @options.fetch(:ruby_project_path, FileUtils.pwd)
    end

    #
    # Generate a path relative to `ruby_toplevel_dir`, given the `path_components` that are passed
    # to `File.join`.
    #
    def ruby_path(*path_components)
      File.join(ruby_toplevel_dir, *path_components)
    end

    # :nocov:

    #
    # Absolute path to the shared libruby.
    #
    def libruby_path
      @libruby_path ||= File.join(RbConfig::CONFIG['libdir'], RbConfig::CONFIG['LIBRUBY_SO'])
    end

    # :nocov:

    #
    # The top-level directory of the Cargo project. Defaults to the current working directory.
    #
    def rust_toplevel_dir
      @rust_toplevel_dir ||= @options.fetch(:cargo_project_path, FileUtils.pwd)
    end

    #
    # Generate a path relative to `rust_toplevel_dir`, given the `path_components` that are
    # passed to `File.join`.
    #
    def rust_path(*path_components)
      File.join(rust_toplevel_dir, *path_components)
    end

    #
    # Path to the Rust shared library in the context of the Ruby project.
    #
    def ruby_extension_path
      ruby_path('lib', shared_library)
    end

    #
    # The basic semantic versioning format.
    #
    DEFAULT_TAG_REGEX = /^(v\d+\.\d+\.\d+)$/

    #
    # The format (as a regular expression) that git tags containing Rust binary
    # tarballs are supposed to match. Defaults to `DEFAULT_TAG_FORMAT`.
    #
    def git_tag_regex
      @git_tag_regex ||= begin
        if @options[:git_tag_regex]
          Regexp.new(@options[:git_tag_regex])
        else
          DEFAULT_TAG_REGEX
        end
      end
    end

    #
    # Parsed TOML object (courtesy of `tomlrb`).
    #
    def toml
      @toml ||= Tomlrb.load_file(rust_path('Cargo.toml'), symbolize_keys: true)
    end

    #
    # Alias to the crate version specified in the TOML file.
    #
    def crate_version
      toml[:package][:version]
    end

    #
    # The Thermite-specific config from the TOML file.
    #
    def toml_config
      @toml_config ||= begin
        # Not using .dig to be Ruby < 2.3 compatible
        if toml && toml[:package] && toml[:package][:metadata] &&
           toml[:package][:metadata][:thermite]
          toml[:package][:metadata][:thermite]
        else
          {}
        end
      end
    end

    # :nocov:

    #
    # Linker flags for libruby.
    #
    def dynamic_linker_flags
      @dynamic_linker_flags ||= RbConfig::CONFIG['DLDFLAGS'].strip
    end

    private

    def dlext
      RbConfig::CONFIG['DLEXT']
    end

    def rbconfig_ruby_version
      RbConfig::CONFIG['ruby_version']
    end
  end
end
