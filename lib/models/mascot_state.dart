enum TamagoState {
  egg,
  cracking,
  peeking,
  halfOut,
  hatched,
}

extension TamagoStateExt on TamagoState {
  String get label {
    switch (this) {
      case TamagoState.egg:
        return 'Ei';
      case TamagoState.cracking:
        return 'Riss';
      case TamagoState.peeking:
        return 'Augen raus';
      case TamagoState.halfOut:
        return 'Halb geschlüpft';
      case TamagoState.hatched:
        return 'Geschlüpft';
    }
  }

  String get emoji {
    switch (this) {
      case TamagoState.egg:
        return '🥚';
      case TamagoState.cracking:
        return '🥚';
      case TamagoState.peeking:
        return '🐣';
      case TamagoState.halfOut:
        return '🐣';
      case TamagoState.hatched:
        return '🐥';
    }
  }

  int get minXp {
    switch (this) {
      case TamagoState.egg:
        return 0;
      case TamagoState.cracking:
        return 500;
      case TamagoState.peeking:
        return 1500;
      case TamagoState.halfOut:
        return 3000;
      case TamagoState.hatched:
        return 5000;
    }
  }
}
