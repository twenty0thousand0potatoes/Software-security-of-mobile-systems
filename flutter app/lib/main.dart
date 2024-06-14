import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

typedef Sha256Func = Void Function(Pointer<Double>, Int32, Pointer<Uint8>);
typedef Sha256 = void Function(Pointer<Double>, int, Pointer<Uint8>);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dylib = DynamicLibrary.open('libnative-lib.so');
  late Sha256 sha256;
  List<double>? _gyroscopeValues;
  bool _isButtonBlocked = false;
  bool gyrosFlag = false;
  double _progressValue = 0.0;
  List<double> entropy = [];
  String sha256Hash = '';
  bool isHashCalculated = false;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    sha256 = dylib.lookupFunction<Sha256Func, Sha256>('sha256');
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _resetState() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    setState(() {
      _gyroscopeValues = null;
      _isButtonBlocked = false;
      gyrosFlag = false;
      _progressValue = 0.0;
      entropy.clear();
      sha256Hash = '';
      isHashCalculated = false;
    });
  }

  void _calculateSha256() {
    if (!isHashCalculated) {
      final hashBytesPtr = calloc<Uint8>(32);

      final entropyPtr = entropy.toNativeDoubleArray();
      print(entropy);
      sha256(entropyPtr, entropy.length, hashBytesPtr);

      final hash = hashBytesPtr.asTypedList(32);
      
      print(hash);
      sha256Hash = hash.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');

      calloc.free(hashBytesPtr);
      calloc.free(entropyPtr);

      setState(() {
        isHashCalculated = true;
      });
    }
  }

  void _handleGyroscopeEvent(AccelerometerEvent event) {
    if (_progressValue < 1.0) {
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
        if (event.x > 5 && !gyrosFlag) {
          gyrosFlag = true;
          //_progressValue += 0.015625; // if we want to collect 64 values
          _progressValue += 0.05;
          entropy.add(double.parse(event.x.toStringAsFixed(6)));
        } else if (event.x < 0 && gyrosFlag) {
          gyrosFlag = false;
          _progressValue += 0.05;
          //_progressValue += 0.015625; // if we want to collect 64 values
          entropy.add(double.parse(event.x.toStringAsFixed(6)));
        }
        _progressValue = _progressValue.clamp(0.0, 1.0);
        if (_progressValue == 1.0 && !isHashCalculated) {
          _calculateSha256();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gyroscope = _gyroscopeValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList()
        .join(', ');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Gyroscope Example'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonBlocked ? Color(0xFF191919) : Color(0xFF090909),
            ),
            onPressed: _isButtonBlocked
                ? _resetState
                : () {
              _streamSubscriptions.add(accelerometerEvents.listen(_handleGyroscopeEvent));
              setState(() {
                _isButtonBlocked = true;
              });
            },
            child: Text(
              _progressValue == 1.0 ? 'Restart' : 'Get Gyroscope Values',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isButtonBlocked && _progressValue < 1.0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Gyroscope: $gyroscope',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (_isButtonBlocked && _progressValue < 1.0)
            Container(
              width: double.infinity,
              height: 10,
              color: Color(0xff191919),
              child: FractionallySizedBox(
                widthFactor: _progressValue,
                child: Container(
                  color: Colors.deepPurple,
                ),
              ),
            ),
          if (_progressValue == 1.0)
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: entropy.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            entropy[index].toString(),
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'SHA256 Hash: $sha256Hash',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

extension NativeDoubleArray on List<double> {
  Pointer<Double> toNativeDoubleArray() {
    final ptr = calloc<Double>(this.length);
    for (var i = 0; i < this.length; i++) {
      ptr[i] = this[i];
    }
    return ptr;
  }
}
