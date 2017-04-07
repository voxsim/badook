require 'spec_helper'

module Capybara::Badook
  describe PhantomJS do
    let(:client_params) { {} }
    subject { PhantomJS.new(client_params) }

    context '#initialize' do
      it 'raises an error if phantomjs is too old' do
        stub_version('1.3.0')
        expect { subject }.to raise_error(Cliver::Dependency::VersionMismatch)
      end

      it 'does not raise an error if phantomjs is too new' do
        begin
          stub_version('1.10.0 (development)')
          expect { subject }.to_not raise_error
        ensure
          subject.stop # process has been spawned, stopping
        end
      end

      it 'shows the detected version in the version error message' do
        stub_version('1.3.0')
        expect { subject }.to raise_error(Cliver::Dependency::VersionMismatch) do |e|
          expect(e.message).to include('1.3.0')
        end
      end

      context 'when phantomjs does not exist' do
        let(:client_params) { { path: '/does/not/exist' } }

        it 'raises an error' do
          expect { subject }.to raise_error(Cliver::Dependency::NotFound)
        end
      end

      def stub_version(version)
        allow_any_instance_of(Cliver::ShellCapture).to receive_messages(
          stdout: "#{version}\n",
          command_found: true
        )
      end
    end

    unless Capybara::Badook.windows?
      it 'forcibly kills the child if it does not respond to SIGTERM' do
        client = PhantomJS.new

        allow(Process).to receive_messages(spawn: 5678)
        allow(Process).to receive(:wait) do
          @count = @count.to_i + 1
          @count == 1 ? sleep(3) : 0
        end

        client.start

        expect(Process).to receive(:kill).with('TERM', 5678).ordered
        expect(Process).to receive(:kill).with('KILL', 5678).ordered

        client.stop
      end
    end
  end
end
