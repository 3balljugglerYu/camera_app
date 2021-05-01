import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'display_picture_screen.dart';

/*　使用するカメラを確立するための記述　***********************************************/
Future<void> main() async {
  //WidgetsFlutterBindingクラス：runApp()を呼び出す前に、Flutter Engineの機能を利用したい場合に使う。
  //WidgetsFlutterBinding.ensureInitialized();　runAppの前にflutterアプリの機能を利用する場合に必要なメソッド。
  WidgetsFlutterBinding.ensureInitialized();

  //availableCamerasメソッド：デバイスから利用可能なカメラをいくつか探す。
  final cameras = await availableCameras();

  //利用可能なカメラのリストからカメラを決定する。
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      //適切なカメラをTakePicturesScreenウィジェットに渡す。
      home: TakePictureScreen(
        camera: firstCamera,
      ),
    ),
  );
}

/* **************************************************************************** */
//デバイスのカメラへの接続が確立され、カメラを制御してカメラのフィードにプレビューを表示できるようにする。。

//ユーザーが特定のカメラを使用して、写真を撮ることができるスクリーンの作成。
class TakePictureScreen extends StatefulWidget {
  //cameraを初期化する。（コンストラクタ）
  final CameraDescription camera;

  //写真を撮る画面に使用するカメラはコンストラクタのcameraを使用。
  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  //stateクラスに2つの変数を格納する。
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    //カメラからの現在の出力を表示するためには、CameraControllerを作成する。
    _controller = CameraController(
      //利用可能なカメラリストから使用するカメラを取得する。上記で選択したcamera。
      widget.camera,

      //利用するカメラの解像度を定義。
      ResolutionPreset.medium,
    );

    //コントローラーを初期化する。返り値は、Futureとなる。
    //CameraControllerを初期化しないと、カメラを使用してプレビューを表示したり、写真をとったりすることができない。
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    //ウィジェットが破棄されたら、コントローラーを破棄する。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),

      //controllerが初期化されるまで待ってから、カメラのプレビューを実装する。
      //controllerの初期化が完了するまで、FutureBuilderを使用し、ローディングスピナーを表示する。
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          //ConnectionStateが、nullでなければ、
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(
              //ローディングスピナーの表示
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            //カメラを初期化する。必ず必要。
            await _initializeControllerFuture;

            final image = await _controller.takePicture();

            //写真を撮った場合は、新しい画面に遷移する
            Navigator.push(
              context,
              MaterialPageRoute(
                //自動で生成されたパスをDisplayPictureScreenウィジェットに渡す。
                builder: (context) => DisplayPictureScreen(
                  imagePath: image?.path,
                ),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}