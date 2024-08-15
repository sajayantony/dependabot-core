# typed: false
# frozen_string_literal: true

require "spec_helper"
require "dependabot/updater"
require "dependabot/package_manager"
require "dependabot/notices"

RSpec.describe Dependabot::Updater::PullRequestHelpers do
  let(:dummy_class) do
    Class.new do
      include Dependabot::Updater::PullRequestHelpers

      attr_accessor :notices

      def initialize
        @notices = []
      end
    end
  end

  let(:dummy_instance) { dummy_class.new }

  before do
    allow(Dependabot::Experiments).to receive(:enabled?).with(:add_deprecation_warn_to_pr_message).and_return(true)
  end

  after do
    Dependabot::Experiments.reset!
  end

  describe "#add_deprecation_notice" do
    let(:package_manager) do
      Class.new(Dependabot::PackageManagerBase) do
        def name
          "bundler"
        end

        def version
          Dependabot::Version.new("1")
        end

        def deprecated_versions
          [Dependabot::Version.new("1")]
        end

        def supported_versions
          [Dependabot::Version.new("2"), Dependabot::Version.new("3")]
        end
      end.new
    end

    context "when package manager is provided and is deprecated" do
      it "adds a deprecation notice to the notices array" do
        expect do
          dummy_instance.add_deprecation_notice(notices: dummy_instance.notices, package_manager: package_manager)
        end
          .to change { dummy_instance.notices.size }.by(1)

        notice = dummy_instance.notices.first
        expect(notice.mode).to eq("WARN")
        expect(notice.type).to eq("bundler_deprecated_warn")
        expect(notice.package_manager_name).to eq("bundler")
      end
    end

    context "when package manager is not provided" do
      it "does not add a deprecation notice to the notices array" do
        expect { dummy_instance.add_deprecation_notice(notices: dummy_instance.notices, package_manager: nil) }
          .not_to(change { dummy_instance.notices.size })
      end
    end

    context "when package manager is not deprecated" do
      let(:package_manager) do
        Class.new(Dependabot::PackageManagerBase) do
          def name
            "bundler"
          end

          def version
            Dependabot::Version.new("2")
          end

          def deprecated_versions
            [Dependabot::Version.new("1")]
          end

          def supported_versions
            [Dependabot::Version.new("2"), Dependabot::Version.new("3")]
          end
        end.new
      end

      it "does not add a deprecation notice to the notices array" do
        expect do
          dummy_instance.add_deprecation_notice(notices: dummy_instance.notices, package_manager: package_manager)
        end
          .not_to(change { dummy_instance.notices.size })
      end
    end
  end
end
