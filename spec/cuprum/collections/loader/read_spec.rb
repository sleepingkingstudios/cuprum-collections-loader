# frozen_string_literal: true

require 'yaml'

require 'cuprum/collections/basic/collection'

require 'cuprum/collections/loader/read'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Cuprum::Collections::Loader::Read do
  subject(:command) { described_class.new(**constructor_options) }

  let(:data_path)           { 'path/to/data' }
  let(:constructor_options) { { data_path: data_path } }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to respond_to(:new)
        .with(0).arguments
        .and_keywords(:data_path)
    end
  end

  describe '#call' do
    shared_examples 'should check for the presence of the data directory' do
      # rubocop:disable RSpec/ExampleLength
      it 'should check for the presence of the data directory',
        :aggregate_failures \
      do
        command.call(relative_path: relative_path)

        expect(file_proxy).to have_received(:exist?).with(qualified_path)

        if dirs.include?(qualified_path)
          expect(file_proxy).to have_received(:directory?).with(qualified_path)
        else
          expect(file_proxy).not_to have_received(:directory?)
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end

    shared_examples 'should check for the presence of the data file' do
      # rubocop:disable RSpec/ExampleLength
      it 'should check for the presence of the data file',
        :aggregate_failures \
      do
        command.call(relative_path: relative_path)

        expect(file_proxy).to have_received(:exist?).with(file_path)

        if files.include?(file_path)
          expect(file_proxy).to have_received(:file?).with(file_path)
        else
          expect(file_proxy).not_to have_received(:file?).with(file_path)
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end

    shared_examples 'should check for the presence of the global options file' \
    do
      # rubocop:disable RSpec/ExampleLength
      it 'should check for the presence of the global options file',
        :aggregate_failures \
      do
        command.call(relative_path: relative_path)

        expect(file_proxy).to have_received(:exist?).with(global_options_path)

        if files.include?(global_options_path)
          expect(file_proxy).to have_received(:file?).with(global_options_path)
        else
          expect(file_proxy)
            .not_to have_received(:file?)
            .with(global_options_path)
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end

    shared_examples 'should check for the presence of the options file' do
      # rubocop:disable RSpec/ExampleLength
      it 'should check for the presence of the options file',
        :aggregate_failures \
      do
        command.call(relative_path: relative_path)

        expect(file_proxy).to have_received(:exist?).with(options_path)

        if files.include?(options_path)
          expect(file_proxy).to have_received(:file?).with(options_path)
        else
          expect(file_proxy).not_to have_received(:file?).with(options_path)
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end

    shared_examples 'should validate the options' do
      context 'when the options file is invalid YAML' do
        let(:raw_options) do
          <<~YAML
            ---
            test: - nope
          YAML
        end
        let(:expected_message) do
          YAML.safe_load(raw_options)
        rescue Psych::SyntaxError => exception
          exception.message
        end
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::ParseError.new(
            format:    :yaml,
            message:   expected_message,
            raw_value: raw_options
          )
        end

        it 'should return a failing result' do
          expect(command.call(relative_path: relative_path))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the options file is unsafe YAML' do
        let(:raw_options) do
          <<~YAML
            default: &default
              adapter: /dev/null

            development:
              <<: *default
          YAML
        end
        let(:expected_message) do
          YAML.safe_load(raw_options)
        rescue Psych::BadAlias => exception
          exception.message
        end
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::ParseError.new(
            format:    :yaml,
            message:   expected_message,
            raw_value: raw_options
          )
        end

        it 'should return a failing result' do
          expect(command.call(relative_path: relative_path))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end

      context 'when the options file parses to an invalid value' do
        let(:raw_options) do
          <<~YAML
            ---
            invalid value
          YAML
        end
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::DataError.new(
            format:       :yaml,
            parsed_value: 'invalid value',
            raw_value:    raw_options,
            message:      'options must be a Hash'
          )
        end

        it 'should return a failing result' do
          expect(command.call(relative_path: relative_path))
            .to be_a_failing_result
            .with_error(expected_error)
        end
      end
    end

    shared_examples 'should load the data and options' do
      context 'when the files do not exist' do
        let(:expected_error) do
          Cuprum::Collections::Loader::Errors::LoadError.new(
            file_path: qualified_path,
            message:   'no such file or directory'
          )
        end

        it 'should return a failing result' do
          expect(command.call(relative_path: relative_path))
            .to be_a_failing_result
            .with_error(expected_error)
        end

        include_examples 'should check for the presence of the data directory'

        include_examples 'should check for the presence of the data file'
      end

      context 'when the data directory exists' do
        shared_examples 'should parse the YAML data' do
          it 'should parse the YAML data', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
            parser = instance_double(
              Cuprum::Collections::Loader::Formats::ParseYaml,
              call: []
            )

            allow(Cuprum::Collections::Loader::Formats::ParseYaml)
              .to receive(:new)
              .and_return(parser)

            command.call(relative_path: relative_path)

            expect(Cuprum::Collections::Loader::Formats::ParseYaml)
              .to have_received(:new)
              .with(options: options)
            raw_data.each do |raw_hash|
              expect(parser).to have_received(:call).with(raw_hash)
            end
          end
        end

        let(:data) do
          [
            {
              'name'       => 'Red',
              'generation' => 1,
              'starters'   => "Bulbasaur\nCharmander\nSquirtle"
            },
            {
              'name'       => 'Gold',
              'generation' => 2,
              'starters'   => "Chikorita\nCyndaquil\nTotodile"
            },
            {
              'name'       => 'Ruby',
              'generation' => 3,
              'starters'   => "Mudkip\nTorchic\nTreecko"
            }
          ]
        end
        let(:options)      { {} }
        let(:raw_data)     { data.map { |hsh| YAML.dump(hsh) } }
        let(:options_path) { "#{qualified_path}/_options.yml" }
        let(:dirs)         { [*super(), qualified_path] }
        let(:data_files) do
          %w[gen1 gen2 gen3]
            .map { |file_name| "#{qualified_path}/#{file_name}.yml" }
        end
        let(:files) do
          super().merge(data_files.zip(raw_data).to_h)
        end
        let(:expected) do
          [
            data.map do |hsh|
              hsh.transform_values do |value|
                value.is_a?(String) ? value.tr("\n", ' ') : value
              end
            end,
            {}
          ]
        end

        it 'should return a passing result' do
          expect(command.call(relative_path: relative_path))
            .to be_a_passing_result
            .with_value(expected)
        end

        include_examples 'should check for the presence of the data directory'

        it 'should not check for the presence of the data file',
          :aggregate_failures \
        do
          command.call(relative_path: relative_path)

          expect(file_proxy).not_to have_received(:exist?).with(file_path)

          expect(file_proxy).not_to have_received(:file?).with(file_path)
        end

        include_examples 'should check for the presence of the options file'

        include_examples \
          'should check for the presence of the global options file'

        it 'should load the data files', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
          command.call(relative_path: relative_path)

          expect(dir_proxy)
            .to have_received(:glob)
            .with("#{qualified_path}/*.yml")

          data_files.each do |data_file_path|
            expect(file_proxy).to have_received(:read).with(data_file_path)
          end
        end

        include_examples 'should parse the YAML data'

        context 'when the global options file exists' do
          let(:options)     { { 'find_by' => 'slug' } }
          let(:raw_options) { YAML.dump(options) }
          let(:files) do
            super().merge(global_options_path => raw_options)
          end
          let(:expected) do
            [
              data.map do |hsh|
                hsh.transform_values do |value|
                  value.is_a?(String) ? value.tr("\n", ' ') : value
                end
              end,
              options
            ]
          end

          it 'should return a passing result' do
            expect(command.call(relative_path: relative_path))
              .to be_a_passing_result
              .with_value(expected)
          end

          include_examples \
            'should check for the presence of the global options file'

          include_examples 'should check for the presence of the options file'

          it 'should load the global options file' do
            command.call(relative_path: relative_path)

            expect(file_proxy).to have_received(:read).with(global_options_path)
          end

          include_examples 'should parse the YAML data'

          include_examples 'should validate the options'
        end

        context 'when the options file exists' do
          let(:options)     { { 'starters' => { 'multiline' => true } } }
          let(:raw_options) { YAML.dump(options) }
          let(:files)       { super().merge(options_path => raw_options) }
          let(:expected)    { [data, options] }

          it 'should return a passing result' do
            expect(command.call(relative_path: relative_path))
              .to be_a_passing_result
              .with_value(expected)
          end

          include_examples \
            'should check for the presence of the global options file'

          include_examples 'should check for the presence of the options file'

          it 'should load the options file' do
            command.call(relative_path: relative_path)

            expect(file_proxy).to have_received(:read).with(options_path)
          end

          include_examples 'should parse the YAML data'

          include_examples 'should validate the options'
        end

        context 'when both local and global options exist' do
          let(:global_options) { { 'find_by' => 'slug' } }
          let(:local_options)  { { 'starters' => { 'multiline' => true } } }
          let(:options)        { global_options.merge(local_options) }
          let(:files) do
            super().merge(
              global_options_path => YAML.dump(global_options),
              options_path        => YAML.dump(local_options)
            )
          end
          let(:expected) { [data, options] }

          it 'should return a passing result' do
            expect(command.call(relative_path: relative_path))
              .to be_a_passing_result
              .with_value(expected)
          end

          include_examples \
            'should check for the presence of the global options file'

          include_examples 'should check for the presence of the options file'

          it 'should load the global options file' do
            command.call(relative_path: relative_path)

            expect(file_proxy).to have_received(:read).with(global_options_path)
          end

          it 'should load the options file' do
            command.call(relative_path: relative_path)

            expect(file_proxy).to have_received(:read).with(options_path)
          end

          include_examples 'should parse the YAML data'
        end
      end

      context 'when the data file exists' do
        shared_examples 'should parse the YAML data' do
          it 'should parse the YAML data', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
            parser = instance_double(
              Cuprum::Collections::Loader::Formats::ParseYaml,
              call: []
            )

            allow(Cuprum::Collections::Loader::Formats::ParseYaml)
              .to receive(:new)
              .and_return(parser)

            command.call(relative_path: relative_path)

            expect(Cuprum::Collections::Loader::Formats::ParseYaml)
              .to have_received(:new)
              .with(options: options)
            expect(parser).to have_received(:call).with(raw_data)
          end
        end

        let(:data) do
          [
            {
              'name'       => 'Red',
              'generation' => 1,
              'starters'   => "Bulbasaur\nCharmander\nSquirtle"
            },
            {
              'name'       => 'Gold',
              'generation' => 2,
              'starters'   => "Chikorita\nCyndaquil\nTotodile"
            },
            {
              'name'       => 'Ruby',
              'generation' => 3,
              'starters'   => "Mudkip\nTorchic\nTreecko"
            }
          ]
        end
        let(:options)      { {} }
        let(:raw_data)     { YAML.dump(data) }
        let(:options_path) { "#{qualified_path}_options.yml" }
        let(:files)        { super().merge(file_path => raw_data) }
        let(:expected) do
          [
            data.map do |hsh|
              hsh.transform_values do |value|
                value.is_a?(String) ? value.tr("\n", ' ') : value
              end
            end,
            {}
          ]
        end

        it 'should return a passing result' do
          expect(command.call(relative_path: relative_path))
            .to be_a_passing_result
            .with_value(expected)
        end

        include_examples 'should check for the presence of the data directory'

        include_examples 'should check for the presence of the data file'

        include_examples 'should check for the presence of the options file'

        it 'should load the data file' do
          command.call(relative_path: relative_path)

          expect(file_proxy).to have_received(:read).with(file_path)
        end

        it 'should not load the options file' do
          command.call(relative_path: relative_path)

          expect(file_proxy).not_to have_received(:read).with(options_path)
        end

        include_examples 'should parse the YAML data'

        context 'when the options file exists' do
          let(:options)     { { 'starters' => { 'multiline' => true } } }
          let(:raw_options) { YAML.dump(options) }
          let(:files)       { super().merge(options_path => raw_options) }
          let(:expected)    { [data, options] }

          it 'should return a passing result' do
            expect(command.call(relative_path: relative_path))
              .to be_a_passing_result
              .with_value(expected)
          end

          include_examples 'should check for the presence of the options file'

          it 'should load the options file' do
            command.call(relative_path: relative_path)

            expect(file_proxy).to have_received(:read).with(options_path)
          end

          include_examples 'should parse the YAML data'

          include_examples 'should validate the options'
        end
      end
    end

    let(:dirs)                { [] }
    let(:files)               { {} }
    let(:exists)              { dirs + files.keys }
    let(:data_files)          { [] }
    let(:qualified_path)      { File.join(data_path, relative_path) }
    let(:file_path)           { "#{qualified_path}.yml" }
    let(:global_options_path) { File.join(data_path, '_options.yml') }
    let(:dir_proxy) do
      class_double(Dir, glob: [])
    end
    let(:file_proxy) do
      class_double(
        File,
        directory?: false,
        exist?:     false,
        file?:      false,
        read:       nil
      )
    end
    let(:relative_path) { 'books' }
    let(:constructor_options) do
      super().merge(dir_proxy: dir_proxy, file_proxy: file_proxy)
    end

    before(:example) do
      allow(file_proxy).to receive(:directory?) { |path| dirs.include?(path) }
      allow(file_proxy).to receive(:exist?)     { |path| exists.include?(path) }
      allow(file_proxy).to receive(:file?)      { |path| files.key?(path) }

      allow(file_proxy).to receive(:read) do |path|
        files.fetch(path) { raise Errno::ENOENT, "rb_sysopen - #{path}" }
      end

      allow(dir_proxy).to receive(:glob).and_return(data_files)
    end

    it 'should define the method' do
      expect(command)
        .to be_callable
        .with(0).arguments
        .and_keywords(:relative_path)
    end

    include_examples 'should load the data and options'

    describe 'with a namespaced resource' do
      let(:relative_path) { 'authentication/users' }

      include_examples 'should load the data and options'
    end
  end

  describe '#data_path' do
    include_examples 'should define reader', :data_path, -> { data_path }
  end

  describe '#dir_proxy' do
    include_examples 'should define private reader', :dir_proxy, Dir
  end

  describe '#file_proxy' do
    include_examples 'should define private reader', :file_proxy, File
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
