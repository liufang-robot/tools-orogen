# frozen_string_literal: true

module OroGen
    module Spec
        # Specification for an input port
        class InputPort < Port
            attr_reader :required_connection_type

            def initialize(*args)
                super
                @required_connection_type = :data
            end

            def input?
                true
            end

            # True if connections to this port must use a data policy.
            #
            # This should not be useful in general
            def needs_data_connection
                @required_connection_type = :data
                self
            end

            # Returns true if the task context requires connections to this port to
            # be reliable (i.e. non-lossy).
            #
            # See #needs_reliable_policy for more information
            def needs_reliable_connection?
                @needs_reliable_connection
            end

            # Declares that the task context requires a non-lossy policy
            #
            # Latest-value connections may coalesce samples. Meeting this
            # requirement therefore depends on deployment timing, for example
            # running the consumer more often than the producer publishes.
            def needs_reliable_connection
                @needs_reliable_connection = true
                self
            end

            # In oroGen, input ports are cleared in the startHook()
            #
            # Calling #do_not_clean disables this behaviour for this particular
            # port
            def do_not_clean
                @do_not_clean = true
            end

            # If true, this port accepts to have multiple active connections at the same time
            def multiplexes?
                !!@multiplexes
            end

            # Declares that this port accepts multiple active connections
            def multiplexes
                @multiplexes = true
                self
            end
        end
    end
end
