import ceylon.time {
	Duration
}

import java.util.concurrent {
	TimeUnit,
	CountDownLatch
}


"Provides the result of an operation synchronously, ie. blocking."
shared interface SyncHasValue<out Result=Anything>
		satisfies HasValue<Result> {
	"Synchronously (blocking) get the value of this computation."
	throws(`class TimeoutException`, "if no value is set until the maximum wait is reached")
	shared formal Result syncGet(Duration maximumWait);
}

"Synchronous implementation of [[HasValue]] which allows blocking until a value is present."
shared class SynchronousValue<Result=Anything>()
		satisfies SyncHasValue<Result> & AcceptsValue<Result> {
	
	value promise = WritableOncePromise<Result>();
	value latch = CountDownLatch(1);
	
	shared actual Result syncGet(Duration maximumWait) {
		value done = latch.await(maximumWait.milliseconds, TimeUnit.\iMILLISECONDS);
		if (done) {
			value result = promise.getOrNoValue();
			if (is Result result) { return result; }
			if (is Exception result) { throw result; }
			throw Exception("Invalid internal state");
		} else {
			throw TimeoutException();
		}
	}
	
	getOrNoValue() => promise.getOrNoValue();
	
	shared actual void set(Result|Exception result) {
		promise.set(result);
		latch.countDown();
	}
	
}
