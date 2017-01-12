var exec = require("cordova/exec"),
    channel = require("cordova/channel");

var localNotificationData;

module.exports = {
    /**
     * Initializing geofence plugin
     *
     * @name initialize
     * @param  {Function} success callback
     * @param  {Function} error callback
     *
     * @return {Promise}
     */
    initialize: function (success, error) {
        return execPromise(success, error, "GeofencePlugin", "initialize", []);
    },
    /**
     * Adding new geofence to monitor.
     * Geofence could override the previously one with the same id.
     *
     * @name addOrUpdate
     * @param {Geofence|Array} geofences
     * @param {Function} success callback
     * @param {Function} error callback
     *
     * @return {Promise}
     */
    addOrUpdate: function (geofences, success, error) {
        if (!Array.isArray(geofences)) {
            geofences = [geofences];
        }

        geofences.forEach(coerceProperties);

        return execPromise(success, error, "GeofencePlugin", "addOrUpdate", geofences);
    },
    /**
     * Removing geofences with given ids
     *
     * @name  remove
     * @param  {Number|Array} ids
     * @param  {Function} success callback
     * @param  {Function} error callback
     * @return {Promise}
     */
    remove: function (ids, success, error) {
        if (!Array.isArray(ids)) {
            ids = [ids];
        }
        return execPromise(success, error, "GeofencePlugin", "remove", ids);
    },
    /**
     * removing all stored geofences on the device
     *
     * @name  removeAll
     * @param  {Function} success callback
     * @param  {Function} error callback
     * @return {Promise}
     */
    removeAll: function (success, error) {
        return execPromise(success, error, "GeofencePlugin", "removeAll", []);
    },
    /**
     * Getting all watched geofences from the device
     *
     * @name  getWatched
     * @param  {Function} success callback
     * @param  {Function} error callback
     * @return {Promise} if successful returns geofences array stringify to JSON
     */
    getWatched: function (success, error) {
        return execPromise(success, error, "GeofencePlugin", "getWatched", []);
    },
    
    /**
     * Called when app received geofence transition event
     * @param  {Array} geofences
     */
    onTransitionReceived: function (geofences) {
        if(geofences.constructor === Array) {
            if(geofences.length === 1 && geofences[0].openedFromNotification) {
                localNotificationData = geofences;
            }
        }
        
        this.receiveTransition(geofences);
    },
    
    /**
     * If the application was opened from a notification click, returns 
     * the geofence data from that event.
     */
    getOpenedFromNotificationData: function() {
        if(localNotificationData !== undefined) {
            var clonedData = Array.from(localNotificationData);
            localNotificationData = undefined;
            return clonedData;
        }
        
        return undefined;
    },
    
    /**
     * Called when app received geofence transition event
     * @deprecated since version 0.4.0, see onTransitionReceived
     * @param  {Array} geofences
     */
    receiveTransition: function (geofences) {},
    /**
     * Simple ping function for testing
     * @param  {Function} success callback
     * @param  {Function} error callback
     *
     * @return {Promise}
     */
    ping: function (success, error) {
        return execPromise(success, error, "GeofencePlugin", "ping", []);
    }
};

function execPromise(success, error, pluginName, method, args) {
    return new Promise(function (resolve, reject) {
        exec(function (result) {
                resolve(result);
                if (typeof success === "function") {
                    success(result);
                }
            },
            function (reason) {
                reject(reason);
                if (typeof error === "function") {
                    error(reason);
                }
            },
            pluginName,
            method,
            args);
    });
}

function coerceProperties(geofence) {
    if (geofence.id) {
        geofence.id = geofence.id.toString();
    } else {
        throw new Error("Geofence id is not provided");
    }

    if (geofence.latitude) {
        geofence.latitude = coerceNumber("Geofence latitude", geofence.latitude);
    } else {
        throw new Error("Geofence latitude is not provided");
    }

    if (geofence.longitude) {
        geofence.longitude = coerceNumber("Geofence longitude", geofence.longitude);
    } else {
        throw new Error("Geofence longitude is not provided");
    }

    if (geofence.radius) {
        geofence.radius = coerceNumber("Geofence radius", geofence.radius);
    } else {
        throw new Error("Geofence radius is not provided");
    }

    if (geofence.transitionType) {
        geofence.transitionType = coerceNumber("Geofence transitionType", geofence.transitionType);
    } else {
        throw new Error("Geofence transitionType is not provided");
    }

    if (geofence.notification) {
        if (geofence.notification.id) {
            geofence.notification.id = coerceNumber("Geofence notification.id", geofence.notification.id);
        }

        if (geofence.notification.title) {
            geofence.notification.title = geofence.notification.title.toString();
        }

        if (geofence.notification.text) {
            geofence.notification.text = geofence.notification.text.toString();
        }

        if (geofence.notification.smallIcon) {
            geofence.notification.smallIcon = geofence.notification.smallIcon.toString();
        }

        if (geofence.notification.openAppOnClick) {
            geofence.notification.openAppOnClick = coerceBoolean("Geofence notification.openAppOnClick", geofence.notification.openAppOnClick);
        }

        if (geofence.notification.vibration) {
            if (Array.isArray(geofence.notification.vibration)) {
                for (var i=0; i<geofence.notification.vibration.length; i++) {
                    geofence.notification.vibration[i] = coerceInteger("Geofence notification.vibration["+ i +"]", geofence.notification.vibration[i]);
                }
            } else {
                throw new Error("Geofence notification.vibration is not an Array");
            }
        }
    }
}

function coerceNumber(name, value) {
    if (typeof(value) !== "number") {
        console.warn(name + " is not a number, trying to convert to number");
        value = Number(value);

        if (isNaN(value)) {
            throw new Error("Cannot convert " + name + " to number");
        }
    }

    return value;
}

function coerceInteger(name, value) {
    if (!isInt(value)) {
        console.warn(name + " is not an integer, trying to convert to integer");
        value = parseInt(value);

        if (isNaN(value)) {
            throw new Error("Cannot convert " + name + " to integer");
        }
    }

    return value;
}

function coerceBoolean(name, value) {
    if (typeof(value) !== "boolean") {
        console.warn(name + " is not a boolean value, converting to boolean");
        value = Boolean(value);
    }

    return value;
}

function isInt(n){
    return Number(n) === n && n % 1 === 0;
}

// Called after "deviceready" event
channel.deviceready.subscribe(function () {
    // Device is ready now, the listeners are registered
    // and all queued events can be executed.
    exec(null, null, "GeofencePlugin", "deviceReady", []);
});

// Verify if the mettoh Array.from exists otherwise create the method
if (!Array.from) {
  Array.from = (function () {
    var toStr = Object.prototype.toString;
    var isCallable = function (fn) {
      return typeof fn === 'function' || toStr.call(fn) === '[object Function]';
    };
    var toInteger = function (value) {
      var number = Number(value);
      if (isNaN(number)) { return 0; }
      if (number === 0 || !isFinite(number)) { return number; }
      return (number > 0 ? 1 : -1) * Math.floor(Math.abs(number));
    };
    var maxSafeInteger = Math.pow(2, 53) - 1;
    var toLength = function (value) {
      var len = toInteger(value);
      return Math.min(Math.max(len, 0), maxSafeInteger);
    };
    // The length property of the from method is 1.
    return function from(arrayLike/*, mapFn, thisArg */) {
      // 1. Let C be the this value.
      var C = this;
      // 2. Let items be ToObject(arrayLike).
      var items = Object(arrayLike);
      // 3. ReturnIfAbrupt(items).
      if (arrayLike == null) {
        throw new TypeError("Array.from requires an array-like object - not null or undefined");
      }
      // 4. If mapfn is undefined, then let mapping be false.
      var mapFn = arguments.length > 1 ? arguments[1] : void undefined;
      var T;
      if (typeof mapFn !== 'undefined') {
        // 5. else
        // 5. a If IsCallable(mapfn) is false, throw a TypeError exception.
        if (!isCallable(mapFn)) {
          throw new TypeError('Array.from: when provided, the second argument must be a function');
        }
        // 5. b. If thisArg was supplied, let T be thisArg; else let T be undefined.
        if (arguments.length > 2) {
          T = arguments[2];
        }
      }
      // 10. Let lenValue be Get(items, "length").
      // 11. Let len be ToLength(lenValue).
      var len = toLength(items.length);
      // 13. If IsConstructor(C) is true, then
      // 13. a. Let A be the result of calling the [[Construct]] internal method of C with an argument list containing the single item len.
      // 14. a. Else, Let A be ArrayCreate(len).
      var A = isCallable(C) ? Object(new C(len)) : new Array(len);
      // 16. Let k be 0.
      var k = 0;
      // 17. Repeat, while k < len… (also steps a - h)
      var kValue;
      while (k < len) {
        kValue = items[k];
        if (mapFn) {
          A[k] = typeof T === 'undefined' ? mapFn(kValue, k) : mapFn.call(T, kValue, k);
        } else {
          A[k] = kValue;
        }
        k += 1;
      }
      // 18. Let putStatus be Put(A, "length", len, true).
      A.length = len;
      // 20. Return A.
      return A;
    };
  }());
}