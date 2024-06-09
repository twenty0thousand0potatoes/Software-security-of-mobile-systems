import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Определяем типы функций для FFI
typedef Sha256Func = Void Function(Pointer<Double>, Int32, Pointer<Uint32>);
typedef Sha256 = void Function(Pointer<Double>, int, Pointer<Uint32>);

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
  List<double> entropy = []; // Initialize the entropy list
  String sha256Hash = ''; // Store the SHA256 hash result

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
    });
  }

  void _calculateSha256() {
    // Выделяем память под массив для хэша
    final hashBytesPtr = calloc<Uint32>(8); // Предположим, что хэш состоит из 8 элементов типа Uint32

    // Вызываем функцию sha256 и записываем результат в выделенный массив
    final entropyPtr = entropy.toNativeDoubleArray();
    sha256(entropyPtr, entropy.length, hashBytesPtr);

    // Получаем значение хэша из массива
    final hash = hashBytesPtr.asTypedList(8);

    // Освобождаем память, выделенную для массива хэша
    calloc.free(hashBytesPtr);
    calloc.free(entropyPtr);

    // Преобразуем хэш в строку и записываем его в переменную sha256Hash
    sha256Hash = hash.map((byte) => byte.toRadixString(16).padLeft(8, '0')).join('');
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
              _streamSubscriptions.add(
                accelerometerEvents.listen((AccelerometerEvent event) {
                  setState(() {
                    _isButtonBlocked = true;
                    _gyroscopeValues = <double>[event.x, event.y, event.z];
                    if (event.x > 5 && !gyrosFlag) {
                      gyrosFlag = true;
                      _progressValue += 0.05;
                      entropy.add(double.parse(event.x.toStringAsFixed(6)));
                    } else if (event.x < 0 && gyrosFlag) {
                      gyrosFlag = false;
                      _progressValue += 0.05;
                      entropy.add(double.parse(event.x.toStringAsFixed(6)));
                    }
                    _progressValue = _progressValue.clamp(0.0, 1.0);
                    if (_progressValue == 1.0) {
                      _calculateSha256();
                    }
                  });
                }),
              );
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
                    height: 200, // Reduce the height of the window displaying entropy list
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
