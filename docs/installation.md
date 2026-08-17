# Installation

MQT FlowViz is a native macOS and iPadOS application built with Xcode.

## Requirements

- macOS 26.4 or newer
- iPadOS 26.4 or newer when running on an iPad
- Xcode 26.6 or newer
- An Apple ID for running the app on a physical device

## Development Setup

1. Clone the repository:

   ```console
   git clone https://github.com/munich-quantum-toolkit/flowviz.git
   cd flowviz
   ```

2. Open `MQT_FlowViz.xcodeproj` in Xcode.
3. To run on a physical device, select your personal team under **Signing &
   Capabilities** for the MQT FlowViz target.
4. Select a Mac, iPad, or simulator as the target.
5. Press `Cmd + R` to build and run the application.

FlowViz visualizes compilation trace files (`.json`) exported by MQT Predictor.
See
[Tracing the Compilation](https://mqt.readthedocs.io/projects/predictor/en/latest/tracing.html)
for details on generating a compatible trace.
