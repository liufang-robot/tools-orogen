#include "Consumer.hpp"
#include <iostream>
#include <fstream>
#include <cstdlib>

using namespace std;
using namespace data;

Consumer::Consumer(std::string const& name, TaskCore::TaskState initial_state)
    : ConsumerBase(name, initial_state) {}

/// The following lines are template definitions for the various state machine
// hooks defined by Orocos::RTT. See Consumer.hpp for more detailed
// documentation about them.

// bool Consumer::configureHook() { return true; }
bool Consumer::startHook() {
    outfile = new ofstream("data_trigger.txt");
    return true;
}

void Consumer::updateHook()
{
    if (_input.status() == RTT::NewData && _input.data() > 0) {
        *outfile << _input.data() << " " << flush;
        if (_input.data() == 10 && !getenv("OROGEN_TEST_WAIT_FOR_SIGNAL"))
            exit(0);
    }
}

// void Consumer::errorHook() {}
void Consumer::stopHook()
{
    delete outfile;
}
// void Consumer::cleanupHook() {}
