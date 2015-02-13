iOS UIBezierPath Performance
=====

This code dramatically improves performance for common UIBezierPath operations, and it also
brings UIBezierPath API closer to its NSBezierPath counterpart.

## What is this?

This framework adds caching into every UIBezierPath so that common operations can
be performed in constant time. It also adds some missing NSBezierPath methods to the
UIBezierPath class.

After linking this framework into your project, all Bezier paths will automatically be upgraded
to use this new caching. No custom UIBezierPath allocation or initialization is required.

For example, by default there is no O(1) way to retrieve elements from a UIBezierPath. In order to
retrieve the first point of the curve, you must CGPathApply() and interate over the entire path
to retrieve that single point. This framework changes that. For many algorithms, this can 
dramatically affect performance.

## Documentation

View the header files for full documentation.

## Building the framework

This library will generate a proper static framework, as described in [https://github.com/jverkoey/iOS-Framework](https://github.com/jverkoey/iOS-Framework)

There are three targets in the PerformanceBezier Xcode project.

1. The PerformanceBezier target will build the standard .a static framework file
2. The PerformanceBezierTests target contains all of the unit tests for the framework
3. The Framework target will build (1) and bundle it into a standard .framework bundle that can be imported as any other.

The single PerformanceBezier scheme will build (3) above, generating the .framework bundle. Testing this scheme will
run all of the unit tests.

## Including in your project

1. Link against the built framework.
2. Add "-ObjC++ -lstdc++" to the Other Linker Flags in the project's Settings
3. #import <PerformanceBezier/PerformanceBezier.h>

## JRSwizzle

This framework includes and uses the [JRSwizzle](https://github.com/rentzsch/jrswizzle) library, which is
licensed under the MIT license.

## License

<a rel="license" href="http://creativecommons.org/licenses/by/3.0/us/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/3.0/us/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/3.0/us/">Creative Commons Attribution 3.0 United States License</a>.

For attribution, please include:

1. Mention original author "Adam Wulf for Loose Leaf app"
2. Link to https://getlooseleaf.com/opensource/
3. Link to https://github.com/adamwulf/PerformanceBezier



## Support this framework

This framework is created by Adam Wulf ([@adamwulf](https://twitter.com/adamwulf)) as a part of the [Loose Leaf app](https://getlooseleaf.com).

[Buy the app](https://itunes.apple.com/us/app/loose-leaf/id625659452?mt=8&uo=4&at=10lNUI&ct=github) to show your support! :)
