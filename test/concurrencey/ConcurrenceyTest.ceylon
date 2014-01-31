import ceylon.test {
	test,
	assertEquals
}

import concurrencey.internal {
	currentLane
}

import java.lang {
	Thread
}

shared class ConcurrenceyTest() extends TestWithLanes() {
	
	shared test void canRunActionInAnotherLane() {
		value lane = Lane("Lane");
		testingOn(lane);
		
		value actionResult = Action(() => currentLane()).runOn(lane);
		
		value result = actionResult.syncGet();
		assert(is Lane result, result === lane);
	}
	
	shared test void canRunActionWithArgsInAnotherLane() {
		value lane = Lane("Lane B");
		testingOn(lane);
		
		String hi(String s) {
			return s;
		}
		
		value actionResult = Action(() => hi("Hi")).runOn(lane);
		
		value result = actionResult.syncGet();
		assert(result == "Hi");
	}
	
}

shared class PromiseTest() {
	
	shared test void promiseCanProvideResultSynchronously() {
		value promise = WritablePromise<String>();
		promise.set("Hi");
		assertEquals("Hi", promise.syncGet());
	}
	
	shared test void promiseCanProvideResultSynchronouslyWhenValueIsSetLater() {
		value promise = WritablePromise<String>();
		value resultPromise = Action(() => promise.syncGet()).runOn(Lane("test-lane-1"));
		Thread.sleep(50);
		Action(() => promise.set("Hi")).runOn(Lane("test-lane-2"));
		
		value result = resultPromise.syncGet();
		assertEquals("Hi", result);
	}
	
	shared test void promiseCanProvideResultAsync() {
		value promise = WritablePromise<String>();
		promise.set("Hi");
		variable Anything capture = null;
		promise.onCompletion((String|ComputationFailed s) => capture = s);
		assert(exists result = capture);
		assertEquals("Hi", result);
	}
	
	shared test void promiseCanProvideResultAsyncWhenValueIsSetLater() {
		value promise = WritablePromise<String>();
		variable Anything capture = null;
		function doCapture(String|ComputationFailed s) {
			capture = s;
			return s;
		}
		promise.onCompletion(doCapture);
		
		promise.set("Hi");
		
		assert(exists result = capture);
		assertEquals(result, "Hi");
	}
	
	shared test void moreThanOneListenerCanBeAdded() {
		value promise = WritablePromise<String>();
		variable Anything capture1 = null;
		variable Anything capture2 = null;
		variable Anything capture3 = null;
		promise.onCompletion((String|ComputationFailed s) => capture1 = s);
		promise.onCompletion((String|ComputationFailed s) => capture2 = s);
		promise.onCompletion((String|ComputationFailed s) => capture3 = s);
		
		promise.set("Hi");
		
		for (capture in [capture1, capture2, capture3]) {
			assert(exists result = capture);
			assertEquals(result, "Hi");	
		}
	}
	
	shared test void listenerCanBeRemoved() {
		value promise = WritablePromise<String>();
		variable Anything capture1 = null;
		variable Anything capture2 = null;
		
		value id =promise.onCompletion((String|ComputationFailed s) => capture1 = s);
		promise.onCompletion((String|ComputationFailed s) => capture2 = s);
		value ok = promise.stopListening(id);
		promise.set("Hi");
		
		assert(ok);
		assert(capture1 is Null);
		assert(exists c = capture2);
		assertEquals(c, "Hi");
	}
	
}
