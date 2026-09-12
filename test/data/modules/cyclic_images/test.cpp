#include <cyclic_images/TaskBase.hpp>
#include <rtt/extras/SequentialActivity.hpp>
#include <rtt/internal/PortDataAccess.hpp>
#include <rtt/typekit/RealTimeTypekit.hpp>
#include <stdexcept>

namespace {
void require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
class ImageTask : public cyclic_images::TaskBase {
public:
    ImageTask() : TaskBase("images", RTT::TaskContext::Stopped) {
        setActivity(new RTT::extras::SequentialActivity);
    }
    void updateHook() override {
        const std::int32_t& input = _input.data();
        _output.data() = input + 1;
        if (fail) throw std::runtime_error("failed cycle");
    }
    RTT::InputPort<std::int32_t>& input() { return _input; }
    const RTT::OutputPort<std::int32_t>& output() const { return _output; }
    bool fail = false;
};
}
int main() {
    RTT::types::RealTimeTypekitPlugin().loadTypes();
    ImageTask task;
    RTT::OutputPort<std::int32_t> ingress("ingress");
    require(ingress.connectTo(&task.input()), "connect generated input");
    require(task.finalizeConnections(), "finalize generated component");
    require(task.state() == ImageTask::STOPPED, "initial lifecycle snapshot");
    require(task.start(), "start generated component");
    require(task.state() == ImageTask::RUNNING, "start lifecycle snapshot");
    require(RTT::internal::PortDataAccess::publish(ingress, std::int32_t{41}) ==
                RTT::WriteSuccess, "stage ingress");
    require(task.input().data() == 0, "ingress does not mutate working image");
    require(task.getActivity()->trigger(), "execute generated image hook");
    require(task.input().data() == 41 && task.output().snapshot() == 42,
            "automatic generated input acquisition and output publication");
    task.error();
    require(task.state() == ImageTask::RUNTIME_ERROR, "error lifecycle snapshot");
    require(task.stop(), "stop generated component");
    require(task.state() == ImageTask::STOPPED, "stop lifecycle snapshot");
    require(task.start(), "restart generated component");
    const auto committed = task.output().snapshot();
    task.fail = true;
    RTT::internal::PortDataAccess::publish(ingress, std::int32_t{99});
    require(task.getActivity()->trigger(), "execute failed generated hook");
    require(task.state() == ImageTask::EXCEPTION, "exception lifecycle snapshot");
    require(task.output().snapshot() == committed, "failed hook does not publish outputs");
}
