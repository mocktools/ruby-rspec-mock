# Development environment guide

## Preparing

Clone `rspec-mock` repository:

```bash
git clone https://github.com/mocktools/ruby-rspec-mock.git
cd  ruby-rspec-mock
```

Configure latest Ruby environment:

```bash
echo 'ruby-3.1.2' > .ruby-version
cp .circleci/gemspec_latest rspec-mock.gemspec
```

## Commiting

Commit your changes excluding `.ruby-version`, `rspec-mock.gemspec`

```bash
git add . ':!.ruby-version' ':!rspec-mock.gemspec'
git commit -m 'Your new awesome rspec-mock feature'
```
