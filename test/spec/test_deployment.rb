# frozen_string_literal: true

require "orogen/test"

describe OroGen::Spec::Deployment do
    attr_reader :project, :task_model, :deployment

    before do
        @loader = OroGen::Loaders::Files.new
        OroGen::Loaders::RTT.setup_loader(@loader)
        @project = OroGen::Spec::Project.new(@loader)
        @project.name "test"
        @task_model = project.task_context "Test"
        @deployment = project.deployment "test"
    end

    describe "#activity_ordered_tasks" do
        it "is well-behaved if there are no tasks in the deployment" do
            assert_equal [], deployment.activity_ordered_tasks
        end
        it "places masters before the slaves" do
            slave = deployment.task("slave", task_model)
            master = deployment.task("master", task_model)
            deployment.set_master_slave_activity master, slave
            assert_equal [master, slave], deployment.activity_ordered_tasks
        end
        it "raises InternalError if there is a loop" do
            t0 = deployment.task("t0", task_model)
            t1 = deployment.task("t1", task_model)
            deployment.set_master_slave_activity t0, t1
            deployment.set_master_slave_activity t1, t0

            assert_raises(ArgumentError) { deployment.activity_ordered_tasks }
        end
    end

    describe "#task" do
        it "sets the task name to the given name" do
            task = deployment.task("task", "Test")
            assert_equal "task", task.name
        end
        it "sets the task model to the given model" do
            task = deployment.task("task", "Test")
            assert_equal task_model, task.task_model
        end
        it "accepts a task model by object" do
            task = deployment.task("task", task_model)
            assert_equal task_model, task.task_model
        end
        it "raises ArgumentError if the model name cannot be resolved" do
            assert_raises(OroGen::TaskModelNotFound) { deployment.task "name", "Bla" }
        end
        it "raises ArgumentError if a task with the given name already exists" do
            deployment.task("task", task_model)
            assert_raises(ArgumentError) { deployment.task "task", task_model }
        end
        it "sets the deployed task's activity to the default" do
            task_model.default_activity :periodic, 0.1
            task = deployment.task "test", task_model
            assert_equal("RTT::Activity", task.activity_type.class_name)
            assert_equal(0.1, task.period)
        end
    end

    describe "#used_typekits" do
        it "ignores the typekits needed by the project's tasks "\
           "if it does not deploy one" do
            tk = OroGen::Spec::Typekit.new(@loader, "test")
            flexmock(@task_model).should_receive(:used_typekits).and_return([tk])
            assert_equal [], @deployment.used_typekits
        end

        it "returns all the typekits its tasks need" do
            tk = OroGen::Spec::Typekit.new(@loader, "test")
            flexmock(@task_model).should_receive(:used_typekits).and_return([tk])
            deployment.task("task", "Test")
            assert_equal [tk], @deployment.used_typekits
        end

        it "adds the types registered manually" do
            registry = Typelib::Registry.new
            registry.create_numeric "/stub", 4, :sint
            tk = OroGen::Spec::Typekit.new(
                @loader, "test", registry, ["/stub"], ["/stub"]
            )
            @loader.register_typekit_model(tk)
            deployment.load_type "/stub"
            assert_equal [tk], @deployment.used_typekits
        end

        it "ignores virtual typekits" do
            tk = OroGen::Spec::Typekit.new(@loader, "test")
            tk.virtual = true
            flexmock(@task_model).should_receive(:used_typekits).and_return([tk])
            deployment.task("task", "Test")
            assert_equal [], @deployment.used_typekits
        end
    end
end

describe OroGen::Spec::TaskDeployment do
    attr_reader :project, :task_model, :deployment

    before do
        loader = OroGen::Loaders::Files.new
        OroGen::Loaders::RTT.setup_loader(loader)
        @project = OroGen::Spec::Project.new(loader)
        @project.name "test"
        @task_model = project.task_context "Test"
        @deployment = project.deployment "test"
    end

    it "allows to change a default activity" do
        task_model.default_activity :periodic, 0.1
        task = deployment.task "my_name", task_model
        task.triggered
        assert_equal("RTT::Activity", task.activity_type.class_name)
        assert_equal(0, task.period)
    end

    it "raises ArgumentError if trying to change a required activity" do
        task_model.required_activity :periodic, 0.1
        task = deployment.task "my_name", task_model
        assert_raises(ArgumentError) { task.triggered }
    end

    it "raises ArgumentError if trying to change an already explicitly set activity" do
        task = deployment.task "my_name", task_model
        task.triggered
        assert_raises(ArgumentError) { task.periodic(0.1) }
    end
end

describe OroGen::Spec::ConnPolicy do
    describe ".from_hash" do
        def conn_policy
            OroGen::Spec::ConnPolicy
        end

        it "should assign hash values to variables" do
            policy = conn_policy.from_hash type: :data, lock_policy: :locked,
                                           size: 10
            assert_equal(:data, policy.type)
            assert_equal(:locked, policy.lock_policy)
            assert_equal(false, policy.pull)
            assert_equal(10, policy.size)
        end
        it "should set sane defaults if given an empty hash" do
            policy = conn_policy.from_hash({})
            assert_equal(:data, policy.type)
            assert_equal(:lock_free, policy.lock_policy)
            assert_equal(false, policy.pull)
            assert_equal(0, policy.size)
        end
        it "should raise ArgumentError if the connection type is unknown" do
            [:unknown, nil, false, "data"].each do |type|
                assert_raises(ArgumentError) { conn_policy.from_hash type: type }
            end
        end
        it "should raise ArgumentError if the lock_policy is unknown" do
            [:unknown, nil, false].each do |lock_policy|
                assert_raises(ArgumentError) do
                    conn_policy.from_hash lock_policy: lock_policy
                end
            end
        end
        it "rejects obsolete buffered modes instead of generating FIFO connections" do
            %i[buffer circular_buffer].each do |type|
                error = assert_raises(ArgumentError) do
                    conn_policy.from_hash type: type, size: 10
                end
                assert_match(/only :data/, error.message)
            end
        end
        it "rejects unbuffered streaming for a paired deployment connection" do
            assert_raises(ArgumentError) { conn_policy.from_hash type: :unbuffered }
        end
        it "preserves a transport capacity without changing latest-value semantics" do
            policy = conn_policy.from_hash size: 10, pull: true
            assert_equal :data, policy.type
            assert_equal 10, policy.size
            assert policy.pull
            assert_equal 0, conn_policy.from_hash(size: 0).size
        end
        it "rejects a negative transport capacity" do
            assert_raises(ArgumentError) do
                conn_policy.from_hash size: -1
            end
        end
    end

    describe "#to_code" do
        it "generates DATA while preserving locking, pull and transport capacity" do
            policy = OroGen::Spec::ConnPolicy.from_hash(
                type: :data, lock_policy: :locked, pull: true, size: 10
            )
            code = policy.to_code("policy")
            assert_includes code, "policy.type      = RTT::ConnPolicy::DATA;"
            assert_includes code, "policy.lock_policy = RTT::ConnPolicy::LOCKED;"
            assert_includes code, "policy.pull      = true;"
            assert_includes code, "policy.size      = 10;"
        end

        it "rejects obsolete modes assigned directly to a policy" do
            %i[buffer circular_buffer unknown].each do |type|
                policy = OroGen::Spec::ConnPolicy.new
                policy.type = type
                assert_raises(ArgumentError) { policy.to_code("policy") }
            end
        end

        it "validates directly assigned lock and size settings before generation" do
            policy = OroGen::Spec::ConnPolicy.new
            policy.lock_policy = :unknown
            assert_raises(ArgumentError) { policy.to_code("policy") }
            policy.lock_policy = :lock_free
            policy.size = -1
            assert_raises(ArgumentError) { policy.to_code("policy") }
        end
    end
end
