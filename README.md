# oroGen: easy component building for Orocos/RTT

* https://www.rock-robotics.org/documentation/orogen

## What is oroGen ?

oroGen is a specification language and code generator for the Orocos Realtime
Toolkit (RTT). The Orocos/Real Time Toolkit is a C++ library allowing to build
component-based systems (http://www.orocos.org/rtt). The orogen tool allows to
create new components easily.

In oroGen, one write a specification that describes the components you want to
develop. Then, orogen generates the corresponding C++ code and CMake build
system so that you -- the component developer -- has only to care about
implementing the actual functionality.

The remaining of this readme is about oroGen installation. See the user's guide
for more in-depth usage information:

* [oroGen documentation](https://www.rock-robotics.org/documentation/orogen)

## Port connection policies

Deployment connections use `type: :data`: an input receives the latest published
value at its next component cycle. Samples published between cycles may coalesce.
The obsolete `:buffer` and `:circular_buffer` modes are rejected, and input ports
no longer expose `needs_buffered_connection`.

`lock_policy: :lock_free` (the default) and `:locked`, plus the `pull` setting,
retain their existing meanings. `size` is an optional nonnegative transport queue
capacity, with zero selecting the transport default. It does not create a FIFO
at the component input. Applications that require every event must encode that
requirement explicitly, for example with cumulative counters or bounded batches.
Output-only `UNBUFFERED` transport streaming is not a paired deployment port
connection and is not a supported connection policy in this DSL.

## Installation

oroGen is part of the Robot Construction Kit. Check out
[rock-robotics.org](https://rock-robotics.org) for installation instructions.
