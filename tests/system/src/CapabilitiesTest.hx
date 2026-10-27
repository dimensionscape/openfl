package;

import openfl.system.Capabilities;
import utest.Assert;
import utest.Test;
#if (linux && sys)
import sys.io.File;
import sys.FileSystem;
#end

class CapabilitiesTest extends Test
{
	public function test_language()
	{
		// TODO: Confirm functionality

		var exists = Capabilities.language;

		Assert.notNull(exists);
	}

	public function test_os()
	{
		var os = Capabilities.os;

		Assert.notNull(os);
		Assert.equals(os, Capabilities.os);

		#if (linux && sys)
		Assert.isTrue(StringTools.startsWith(os, "Linux"));
		#end
	}

	#if !(linux && sys)
	@Ignored
	#end
	public function test_os_noZombieProcesses()
	{
		#if (linux && sys)
		for (i in 0...5)
		{
			Assert.notNull(Capabilities.os);
		}

		// each task lists the child processes that it started
		var hasChildrenFiles = false;
		var zombies:Array<String> = [];

		for (task in FileSystem.readDirectory("/proc/self/task"))
		{
			var childrenPath = "/proc/self/task/" + task + "/children";
			if (!FileSystem.exists(childrenPath)) continue;
			hasChildrenFiles = true;

			for (pid in StringTools.trim(readProcFile(childrenPath)).split(" "))
			{
				var statPath = "/proc/" + pid + "/stat";
				if (pid == "" || !FileSystem.exists(statPath)) continue;

				// the state follows the command name, which is in parentheses and may contain spaces
				var stat = readProcFile(statPath);
				var commandEnd = stat.lastIndexOf(")");
				var state = StringTools.trim(stat.substr(commandEnd + 1)).charAt(0);

				if (state == "Z")
				{
					zombies.push(pid + " " + stat.substring(stat.indexOf("("), commandEnd + 1));
				}
			}
		}

		if (hasChildrenFiles)
		{
			Assert.equals(0, zombies.length, "Zombie child processes: " + zombies.join(", "));
		}
		else
		{
			Assert.pass("Skipped, the kernel does not provide /proc/self/task/*/children");
		}
		#end
	}

	public function test_screenDPI()
	{
		// TODO: Confirm functionality

		var exists = Capabilities.screenDPI;

		Assert.notNull(exists);
	}

	public function test_screenResolutionX()
	{
		// TODO: Confirm functionality

		var exists = Capabilities.screenResolutionX;

		Assert.notNull(exists);
	}

	public function test_screenResolutionY()
	{
		// TODO: Confirm functionality

		var exists = Capabilities.screenResolutionY;

		Assert.notNull(exists);
	}

	#if (linux && sys)
	private static function readProcFile(path:String):String
	{
		// files in /proc report a size of 0, so read them until the end instead of using File.getContent()
		var input = File.read(path, false);
		var content = input.readAll().toString();
		input.close();
		return content;
	}
	#end
}
