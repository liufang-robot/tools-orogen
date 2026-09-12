#include "Producer.hpp"
#include <iostream>

using namespace std;
using namespace data;

Producer::Producer(std::string const& name, TaskCore::TaskState initial_state)
    : ProducerBase(name, initial_state) {}







/// The following lines are template definitions for the various state machine
// hooks defined by Orocos::RTT. See Producer.hpp for more detailed
// documentation about them.

// bool Producer::configureHook() { return true; }
// bool Producer::startHook() { return true; }

void Producer::updateHook()
{
    static int idx = 0;
    ++idx;

    if (idx == 11) // finish after ten completed cyclic publications
        exit(0);

    _output.data() = idx;
    _output2.data() = idx;

}

// void Producer::errorHook() {}
// void Producer::stopHook() {}
// void Producer::cleanupHook() {}

