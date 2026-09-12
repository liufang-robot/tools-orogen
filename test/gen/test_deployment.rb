# frozen_string_literal: true

require "orogen/gen/test"

class TC_GenerationDeployment < Minitest::Test
    def test_all_activity_types
        project = Project.new
        project.name "test_all_activity_types"
        project.task_context "task"
        deployment = project.deployment "test"

        master = deployment.task("master", "task")
        deployment.task("slave", "task").slave_of(master)
        deployment.task("periodic", "task").periodic(0.1)
        deployment.task("triggered", "task").triggered
        deployment.task("fd_driven", "task").fd_driven
        deployment.task("sequential", "task").sequential
        deployment.task("irq_driven", "task").irq_driven

        create_wc("test_all_activity_types")
        in_wc do
            compile_wc(project)
        end
    end

    def test_data_driven_deployment(*transports)
        build_test_project "modules/data_triggered", transports

        # Check the resulting file
        in_prefix do
            system(File.join("bin", "data"))
            assert_equal "U 1 2 3 4 5 6 7 8 9 10 ", File.read("data_trigger.txt")

            # A native deployment must also finish task lifecycles before
            # destroying ports when termination comes from its supervisor.
            File.unlink("data_trigger.txt")
            pid = Process.spawn(File.join("bin", "data"))
            begin
                deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3
                until File.exist?("data_trigger.txt") &&
                      File.read("data_trigger.txt").include?("2 ")
                    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC),
                                    :<, deadline, "native deployment did not execute"
                    sleep 0.01
                end
                Process.kill("TERM", pid)
                _, status = Process.waitpid2(pid)
                pid = nil
                assert status.success?, "native cyclic deployment did not stop cleanly"
            ensure
                if pid
                    Process.kill("KILL", pid)
                    Process.waitpid(pid)
                end
            end
        end
    end

    def test_fd_driven_deployment(*transports)
        build_test_project "modules/fd_triggered", transports

        # Start the resulting deployment
        in_prefix do
            reader, writer = IO.pipe
            child_pid = Process.spawn({ "FD_DRIVEN_TEST_FILE" => STDIN.fileno.to_s },
                                      "./bin/fd", writer => :close, :in => reader, :close_others => false)

            reader.close
            sleep 0.5
            writer.write("AB")
            sleep 0.5
            writer.write("CDE")
            sleep 0.5
            ::Process.kill "SIGINT", child_pid
            _, result = ::Process.waitpid2(child_pid)
            assert_equal(0, result.exitstatus)
        end
    end

    def test_deployment_with_connection(*transports)
        build_test_project("modules/deployment_with_connection", transports)
    end

    def test_cross_dependencies(*transports)
        # Generate and build all the modules that are needed ...
        build_test_project("modules/typekit_opaque", transports)
        install
        ENV["PKG_CONFIG_PATH"] =
            "#{File.join(prefix_directory, 'lib', 'pkgconfig')}:#{ENV['PKG_CONFIG_PATH']}"

        build_test_project("modules/cross_producer", transports)
        install
        producer_pkgconfig = File.join(prefix_directory, "lib", "pkgconfig")
        build_test_project("modules/cross_consumer", transports)
        install

        ENV["PKG_CONFIG_PATH"] =
            "#{File.join(prefix_directory, 'lib',
                         'pkgconfig')}:#{producer_pkgconfig}:#{ENV['PKG_CONFIG_PATH']}"

        # Start by loading the project specfication and check some properties
        # on it. Then, do the generation, build and test
        Project.load(File.join(path_to_data, "modules", "cross_deployment",
                               "deployment.orogen"))

        build_test_project("modules/cross_deployment", transports)
        install

        in_prefix do
            system(File.join("bin", "cross_deployment"))
            expected = "[U] [1 2] [3 4] [5 6] [7 8] [9 10] [11 12] [13 14] [15 16] "
            assert_equal expected,
                         File.read("cross_dependencies.txt")[0, expected.length]
        end
    end

    def test_cross_dependencies_corba
        test_cross_dependencies("corba")
    end
end
