# frozen_string_literal: true

require "orogen/test"

module OroGen
    module Spec
        describe InputPort do
            before do
                @loader = Loaders::RTT.new("gnulinux")
                @project = Project.new(@loader)
                @task = @project.task_context "Task"
                @port = InputPort.new(@task, "test", "/double")
            end

            it "returns true in input?" do
                assert @port.input?
            end

            it "requires latest-value data connections without a buffered DSL helper" do
                assert_equal :data, @port.required_connection_type
                refute_respond_to @port, :needs_buffered_connection
                assert_same @port, @port.needs_data_connection
                assert_equal :data, @port.required_connection_type
            end
        end
    end
end
