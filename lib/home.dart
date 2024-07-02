import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:contadordevoltaspp/components/firebase_connection.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock/wakelock.dart';

import 'Models/run.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

enum DistanceAction {
  add,
  decrement,
}

class _HomeState extends State<Home> {
  late Timer timer;
  double _distance = 0;
  final double _distanceIncrement = 0.052; // Distância do percurso
  final double _distanceGoal = 4; // Objetivo definido pelo usuário
  double _pace = 0;
  int _laps = 0;
  int _minutes = 0;
  int _seconds = 0;
  bool _isStarted = false; // Controla o botão de finalizar
  bool _isPaused = true; // Controla o botão Play/Pause

  @override
  void initState() {
    super.initState();

    Wakelock.enable();
  }

  // Controla os sons do aplicativo
  Future<void> handleAudio() async {
    final player = AudioPlayer();
    await player.setSource(AssetSource('audios/notify.wav'));
    await player.resume();
  }

  FaIcon faIcon({required IconData icon}) {
    return FaIcon(
      icon,
      size: 40,
      color: Colors.black,
    );
  }

  AlertDialog alertDialog({
    required String title,
    required String content,
    List<Widget>? action,
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
      actions: action,
    );
  }

  AlertDialog alertDialogFinish({
    required String title,
    required Widget content,
    List<Widget>? action,
  }) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: content,
      actions: action,
    );
  }

  TextButton textButton({
    required String title,
    required void Function()? onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.green,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Calcula o Pace
  void handlePace() {
    (_distance > 0) ? _pace = _minutes / _distance : _pace = 0;

    setState(() {
      _pace;
    });
  }

  // Adiciona ou diminui a distância
  void handleDistance({required DistanceAction action}) async {
    if (action == DistanceAction.add) {
      _distance = double.parse(
        (_distance + _distanceIncrement).toStringAsFixed(2),
      );
      _laps++;

      // Notifica com o audio
      await handleAudio();
    } else if (action == DistanceAction.decrement) {
      // Não deixa que a distância fique menor que zero
      // Se o resultado for maior do que zero, retorna ele
      // Se o resultado for "-0.0", retorna o valor "0.0"
      double result = double.parse(
        (_distance - _distanceIncrement).toStringAsFixed(2),
      );
      if (result > -0.0) {
        _distance = result;

        // Notifica com o audio
        await handleAudio();
      } else if (result == -0.0) {
        _distance = 0.0;

        // Notifica com o audio
        await handleAudio();
      }

      // Não deixa que o número de voltas fique menor que zero
      (_laps - 1) >= 0 ? _laps-- : null;
    }

    // Atualiza os resultados
    setState(() {
      _distance;
      _laps;
    });

    // Calcula o Pace
    handlePace();
  }

  // Controla o botão de Play/Pause do cronômetro
  void handleTime() async {
    setState(() {
      _isStarted = !_isStarted;
      _isPaused = !_isPaused;
    });

    // Se apertar o botão Play
    if (_isPaused == false) {
      // Inicia ou despausa o cronômetro
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_seconds == 59) {
            _seconds = 0;
            _minutes++;
          } else {
            _seconds++;
          }
        });

        // Calcula o Pace
        handlePace();
      });
    }
    // Se apertar o botão Pause
    else {
      // Pausa o timer
      timer.cancel();
      // Calcula o Pace
      handlePace();
    }

    // Notifica com o audio
    await handleAudio();
  }

  // Finaliza a atividade
  void handleFinish() async {
    String m;
    String s;

    // Formata os minutos e segundos, adicionando um zero a frente caso sejam menores ou iguais a 9
    (_minutes < 10) ? m = '0$_minutes' : m = '$_minutes';
    (_seconds < 10) ? s = '0$_seconds' : s = '$_seconds';

    // Calcula o Pace
    handlePace();

    // Fecha o dialog aberto
    Navigator.of(context).pop();

    // Exibe enquanto está guardando os dados no banco de dados
    showDialog(
      context: context,
      builder: (context) => alertDialogFinish(
        title: 'AGUARDE',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Os dados estão sendo guardados',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ),
    );

    try {
      await FirebaseConnection().addRegister(
        Run(
          distance: double.parse(_distance.toStringAsFixed(2)),
          time: '$m:$s',
          pace: _pace.toStringAsFixed(2).replaceAll('.', ':'),
          laps: _laps,
          datetime: Timestamp.now(),
        ),
      );

      // Fecha o dialog aberto
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      // Exibe ao guardar os dados corretamente
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) => alertDialogFinish(
          title: 'TUDO CERTO',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 55,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              Text(
                'Os dados foram guardados corretamente!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
          action: [
            textButton(
              title: 'OK',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

      // Zera os valores
      setState(() {
        _distance = 0;
        _pace = 0;
        _laps = 0;
        _minutes = 0;
        _seconds = 0;
        _isStarted = false;
        _isPaused = true;
      });
    } catch (err) {
      // Fecha o dialog aberto
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      // Exibe ao ocorrer uma falha ao guardar os dados
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) => alertDialogFinish(
          title: 'ERRO',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const FaIcon(
                FontAwesomeIcons.circleXmark,
                size: 55,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                'Os dados não foram guardados corretamente! Tente novamente ou tire um print para guardar mais tarde.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
          action: [
            textButton(
              title: 'OK',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                width: media.width,
                height: media.height * 0.7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Quilômetros
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _distance.toStringAsFixed(2),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        Text(
                          'KM',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: media.height * 0.12),

                    // Pace, Voltas e Tempo
                    SizedBox(
                      width: media.width * 0.95,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Pace
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PACE',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _pace.toStringAsFixed(2).replaceAll('.', ':'),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),

                          // Pace
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'VOLTAS',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                _laps.toString(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),

                          // Tempo
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'TEMPO',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Row(
                                children: [
                                  Text(
                                    _minutes < 10 ? '0$_minutes' : '$_minutes',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    _seconds < 10
                                        ? ':0$_seconds'
                                        : ':$_seconds',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Barra de progresso
              Positioned(
                top: media.height * 0.065,
                left: media.width * 0.125,
                child: GestureDetector(
                  child: SizedBox(
                    width: media.width * 0.75,
                    height: media.width * 0.75,
                    child: CircularProgressIndicator(
                      color: Colors.green[700],
                      value: (_distance / _distanceGoal) >= 0
                          ? _distance / _distanceGoal
                          : 0,
                    ),
                  ),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => alertDialog(
                      title: 'CONFIRMAR AÇÃO',
                      content: 'Quer diminuir a distância?',
                      action: [
                        textButton(
                          onPressed: () => Navigator.of(context).pop(),
                          title: 'NÃO',
                        ),

                        // Confirma a diminuição da distância
                        textButton(
                          onPressed: () => {
                            handleDistance(action: DistanceAction.decrement),
                            Navigator.of(context).pop(),
                          },
                          title: 'SIM',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Botões
          Container(
            color: Colors.black,
            width: media.width,
            height: media.height * 0.3,
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Adicionar distância
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutBack,
                  width: _isStarted
                      ? media.width * 0.7 - 5
                      : media.width * 0.5 - 5,
                  height: media.height * 0.3 - 5,
                  child: ElevatedButton(
                    onPressed: () => handleDistance(action: DistanceAction.add),
                    child: faIcon(
                      icon: FontAwesomeIcons.plus,
                    ),
                  ),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Finalizar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutBack,
                      width: _isStarted
                          ? media.width * 0.3 - 5
                          : media.width * 0.5 - 5,
                      height: media.height * 0.15 - 5,
                      child: ElevatedButton(
                        onPressed: () => {
                          // Pausa o timer
                          timer.cancel(),

                          // Calcula o Pace
                          handlePace(),

                          // Altera o botão de Play/Pause para pausado
                          setState(() {
                            _isPaused = true;
                            _isStarted = false;
                          }),

                          showDialog(
                            context: context,
                            builder: (context) => alertDialog(
                              title: 'CONFIRMAR AÇÃO',
                              content: 'Quer finalizar?',
                              action: [
                                textButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  title: 'NÃO',
                                ),

                                // Confirma a finalização
                                textButton(
                                  onPressed: () => {
                                    handleFinish(),
                                  },
                                  title: 'SIM',
                                ),
                              ],
                            ),
                          ),
                        },
                        child: faIcon(
                          icon: FontAwesomeIcons.check,
                        ),
                      ),
                    ),

                    // Play / Pause
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutBack,
                      width: _isStarted
                          ? media.width * 0.3 - 5
                          : media.width * 0.5 - 5,
                      height: media.height * 0.15 - 5,
                      child: ElevatedButton(
                        onPressed: handleTime,
                        child: _isPaused
                            ? faIcon(
                                icon: FontAwesomeIcons.play,
                              )
                            : faIcon(
                                icon: FontAwesomeIcons.pause,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
