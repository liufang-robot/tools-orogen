# frozen_string_literal: true

require "orogen/gen/test"

class TC_GenerationCyclicImages < Minitest::Test
    def test_generated_images_and_lifecycle_observation
        build_test_project("modules/cyclic_images", [], "bin/cyclic_images_test") do |cmake|
            cmake << <<~CMAKE
                add_executable(cyclic_images_test test.cpp)
                target_link_libraries(cyclic_images_test cyclic_images-tasks-${OROCOS_TARGET}
                    ${OrocosRTT_LIBRARIES} ${OROCOS-RTT_TYPEKIT_LIBRARIES})
                install(TARGETS cyclic_images_test RUNTIME DESTINATION bin)
            CMAKE
        end
    end
end
