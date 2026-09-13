#include "Consumer.hpp"
#include <cstdlib>

using namespace cross_deployment;
using namespace std;

Consumer::Consumer(std::string const& name, TaskCore::TaskState initial_state)
    : ConsumerBase(name, initial_state) {}
Consumer::Consumer(std::string const& name, RTT::ExecutionEngine* engine, TaskCore::TaskState initial_state)
    : ConsumerBase(name, engine, initial_state) {}







/// The following lines are template definitions for the various state machine
// hooks defined by Orocos::RTT. See Consumer.hpp for more detailed
// documentation about them.

// bool Consumer::configureHook() { return true; }
// bool Consumer::startHook() { return true; }

void Consumer::updateHook()
{
    const NotOrogenCompatible::Point2D& point = _point.data();
    if (_point.status() == RTT::NewData && point.x() > 0) {
        *io << "[" << point.x() << " " << point.y() << "] " << flush;
        if (point.y() == 20)
            exit(0);
    }
}

// void Consumer::errorHook() {}
// void Consumer::stopHook() {}
// void Consumer::cleanupHook() {}
