# Canvas Data Importer

This gem provides a way to easily import flat files from [Canvas](https://canvaslms.com) Hosted Data into
a database for analytics use.

## Installation

Add this line to your application's Gemfile

```ruby
gem 'canvas_data_importer', github: 'ben-y/canvas_data_importer'
```

and then execute:

```ruby
bundle
```

## Usage

For use in a REPL session or another project, it can be instantiated as such with the following arguments

```ruby
params = {
  database_name: 'database_name', # [required] name of database
  database_schema: 'public', # only used by supported adapters, such as postgresql
  database_host: 'localhost', # host address (defaults to localhost)
  database_port: '5432', # defaults to standard port for the selected database type
  database_username: 'username',
  database_password: 'password',
  database_type: 'postgresql', # database type (such as mysql, postgresql)
  dump: 'latest', # dump ID (defaults to latest dump available)
  canvas_data_key: 'key', # [required] canvas data API key
  canvas_data_secret: 'secret', # [required] canvas data API secret
  requests_only: false, # if true, only requests from selected dump will be imported
  data_only: false # if true, only non-requests data will be imported
}
importer = CanvasDataImporter::Importer.new(params)
importer.import
```

For standalone usage, options can be found by running:

```bash
./bin/cli --help

# Example usage
./bin/cli --database-name=some_database --canvas-data-key=key --canvas-data-secret=secret
```

### Environments

When used in standalone mode, environments can be created to avoid the need to continually
add credentials and other parameters to the command.

An environment can be created by copying the `config/environments/example.yml` file,
giving it the desired environment name, and filling out the new file with all applicable details

```bash
cp config/environments/example.yml config/environments/name_of_environment.yml
```

Once an environment is created, it can be used by using the following command

```bash
./bin/cli --environment=name_of_environment
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ben-y/canvas_data_importer.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
