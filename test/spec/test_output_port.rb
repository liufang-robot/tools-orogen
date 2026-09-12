# frozen_string_literal: true

require "orogen/test"

module OroGen
    module Spec
        describe OutputPort do
            before do
                @loader = Loaders::RTT.new("gnulinux")
                @project = Project.new(@loader)
                @task = @project.task_context "Task"
                @port = OutputPort.new(@task, "test", "/double")
            end

            it "returns false in input?" do
                refute @port.input?
            end

            it "has no optional retention policy for cyclic outputs" do
                refute_respond_to @port, :keep_last_written_value
                refute_respond_to @port, :init_policy
                refute_respond_to @port, :init_policy?
            end
        end
    end
end
