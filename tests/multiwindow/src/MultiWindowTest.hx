package;

import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.NativeWindow;
import openfl.display.NativeWindowInitOptions;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import utest.Assert;
import utest.Async;
import utest.Test;

class MultiWindowTest extends Test
{
	private static inline var FRAMES = 10;

	private var roots:Array<Sprite>;
	private var windows:Array<NativeWindow>;

	public function setup():Void
	{
		roots = [];
		windows = [];
	}

	public function teardown():Void
	{
		for (root in roots)
		{
			if (root.parent != null) root.parent.removeChild(root);
		}

		for (window in windows)
		{
			if (!window.closed) window.close();
		}
	}

	public function test_renderModeChoosesTheRenderer():Void
	{
		Assert.isNull(open("cpu").stage.context3D);

		// By default, a window renders as the main window does, with a Lime that shares
		// OpenGL objects between windows
		var hardware = #if (lime >= "8.4.0") Lib.current.stage.context3D != null #else false #end;
		Assert.equals(hardware, open(null).stage.context3D != null);
	}

	@:timeout(10000)
	public function test_eachWindowDrawsItsShapesAndBitmaps(async:Async):Void
	{
		var window = open("direct");
		if (!hasOpenGL(window, async)) return;

		// One bitmap with its image, drawn in both windows, and one drawn on the GPU,
		// which keeps no image to upload for the second window
		var shared = new BitmapData(50, 50, false, 0xFF00FF00);
		var drawn = new BitmapData(50, 50, false, 0xFF000000);
		drawn.disposeImage();
		drawn.draw(fill(0xFF8000));

		for (stage in [Lib.current.stage, window.stage])
		{
			var root = scene(stage);
			root.addChild(fill(0x0000FF));
			root.addChild(bitmap(shared, 50));
			root.addChild(bitmap(drawn, 100));
		}

		afterFrames(window, async, function(read)
		{
			Assert.equals(0x0000FF, read(25, 25), "a shape was not drawn in the second window");
			Assert.equals(0x00FF00, read(75, 25), "a bitmap drawn in both windows was not drawn in the second");
			Assert.equals(0xFF8000, read(125, 25), "a bitmap drawn on the GPU was not drawn in the second window");
		});
	}

	@:timeout(10000)
	public function test_stage3DDrawsInASecondWindow(async:Async):Void
	{
		var window = open("direct");
		if (!hasOpenGL(window, async)) return;

		// The context is made, and its event dispatched, outside of the window's render
		var stage3D = window.stage.stage3Ds[0];
		var root = scene(window.stage);
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, function(_)
		{
			var context3D = stage3D.context3D;
			context3D.configureBackBuffer(100, 100, 0, false);
			root.addEventListener(Event.ENTER_FRAME, function(_)
			{
				context3D.clear(1, 0, 1, 1);
				context3D.present();
			});
		});
		stage3D.requestContext3D();

		afterFrames(window, async, function(read)
		{
			Assert.equals(0xFF00FF, read(25, 25), "Stage3D was not drawn in the second window");
		});
	}

	@:timeout(10000)
	public function test_anObjectOnNoStageGetsEnterFrameOncePerFrame(async:Async):Void
	{
		var window = open("direct");
		scene(window.stage);
		var onStage = 0, offStage = 0;
		var counter = new Sprite();
		Lib.current.addChild(counter);
		counter.addEventListener(Event.ENTER_FRAME, function(_) onStage++);
		new Sprite().addEventListener(Event.ENTER_FRAME, function(_) offStage++);

		Lib.setTimeout(function()
		{
			if (async.timedOut) return;
			Lib.current.removeChild(counter);
			Assert.isTrue(onStage > 0);
			Assert.isTrue(Math.abs(offStage - onStage) <= 1, 'an object on no stage got ENTER_FRAME $offStage times in $onStage frames');
			async.done();
		}, 500);
	}

	private function open(renderMode:String):NativeWindow
	{
		var options = new NativeWindowInitOptions();
		options.renderMode = renderMode;
		var window = new NativeWindow(options);
		window.width = 200;
		window.height = 100;
		window.activate();
		windows.push(window);
		return window;
	}

	private static function hasOpenGL(window:NativeWindow, async:Async):Bool
	{
		if (Lib.current.stage.context3D != null && window.stage.context3D != null) return true;

		Assert.pass("There is no OpenGL here, so windows were not tested with it");
		async.done();
		return false;
	}

	private function scene(stage:Stage):Sprite
	{
		// A stage that has not changed skips its render, so this one changes every frame
		var root = new Sprite();
		var marker = new Shape();
		marker.graphics.beginFill(0x808080);
		marker.graphics.drawRect(0, 0, 1, 1);
		marker.y = 99;
		root.addChild(marker);
		root.addEventListener(Event.ENTER_FRAME, function(_) marker.x = 199 - marker.x % 2);
		stage.addChild(root);
		roots.push(root);
		return root;
	}

	private static function afterFrames(window:NativeWindow, async:Async, check:(Int->Int->Int)->Void):Void
	{
		var limeWindow = window.stage.window;
		var frames = 0;

		function onRender(_):Void
		{
			if (++frames < FRAMES || async.timedOut) return;
			limeWindow.onRender.remove(onRender);

			// Read back after the stage has drawn, before the frame is shown
			var scale = limeWindow.scale;
			var image = limeWindow.readPixels();
			check(function(x, y) return image == null ? -1 : image.getPixel32(Std.int(x * scale), Std.int(y * scale), ARGB32) & 0xFFFFFF);

			// Teardown closes the window, which is left to after its render
			Lib.setTimeout(async.done, 0);
		}

		limeWindow.onRender.add(onRender, false, -1000);
	}

	private static function fill(color:Int):Shape
	{
		var shape = new Shape();
		shape.graphics.beginFill(color);
		shape.graphics.drawRect(0, 0, 50, 50);
		return shape;
	}

	private static function bitmap(bitmapData:BitmapData, x:Float):Bitmap
	{
		var bitmap = new Bitmap(bitmapData);
		bitmap.x = x;
		return bitmap;
	}
}
