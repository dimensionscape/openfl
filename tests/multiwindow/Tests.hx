import utest.Runner;
import utest.ui.Report;

class Tests
{
	public static function main()
	{
		#if (sys && tools && !air)
		// these tests read back Lime windows on native targets,
		// and you must use Lime tools
		var runner = new Runner();
		runner.addCase(new MultiWindowTest());
		Report.create(runner);
		runner.run();
		#else
		trace("Skipping multiple window tests");
		lime.system.System.exit(0);
		#end
	}
}
