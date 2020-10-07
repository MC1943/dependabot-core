# frozen_string_literal: true

require "native_spec_helper"
require "shared_contexts"

require "dependabot/dependency"

RSpec.describe Functions::VersionResolver do
  include_context "in a temporary bundler directory"
  include_context "stub rubygems compact index"

  let(:version_resolver) do
    described_class.new(
      dependency_name: dependency_name,
      dependency_requirements: dependency_requirements,
      gemfile_name: gemfile_name,
      lockfile_name: lockfile_name
    )
  end

  let(:dependency_name) { "business" }
  let(:dependency_requirements) do
    [{
      file: "Gemfile",
      requirement: requirement_string,
      groups: [],
      source: source
    }]
  end
  let(:source) { nil }

  let(:rubygems_url) { "https://index.rubygems.org/api/v1/" }

  describe "#version_details" do
    subject do
      in_tmp_folder { version_resolver.version_details }
    end

    context "with a private gemserver source" do
      let(:gemfile_fixture_name) { "specified_source" }
      let(:lockfile_fixture_name) { "specified_source.lock" }
      let(:requirement_string) { ">= 0" }

      before do
        gemfury_url = "https://repo.fury.io/greysteil/"
        gemfury_deps_url = gemfury_url + "api/v1/dependencies"

        stub_request(:get, gemfury_url + "versions").
          to_return(status: 200, body: fixture("ruby", "gemfury-index"))
        stub_request(:get, gemfury_url + "info/business").to_return(status: 404)
        stub_request(:get, gemfury_deps_url).to_return(status: 200)
        stub_request(:get, gemfury_deps_url + "?gems=business,statesman").
          to_return(status: 200, body: fixture("ruby", "gemfury_response"))
        stub_request(:get, gemfury_deps_url + "?gems=business").
          to_return(status: 200, body: fixture("ruby", "gemfury_response"))
        stub_request(:get, gemfury_deps_url + "?gems=statesman").
          to_return(status: 200, body: fixture("ruby", "gemfury_response"))
      end

      its([:version]) { is_expected.to eq(Gem::Version.new("1.9.0")) }
    end
  end
end
