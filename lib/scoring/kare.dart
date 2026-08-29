import '../models/enums.dart';

/// Връща задължението в точки според HCP и зоната на борда.
int getCommitment(int hcp, Zones zone) {

  if (zone == Zones.none || zone == Zones.ew) {
    //без зона
    if (hcp == 0) return -1300;
    if (hcp <= 1) return -1300;
    if (hcp <= 2) return -1300;
    if (hcp <= 3) return -1300;
    if (hcp <= 4) return -1200;
    if (hcp <= 5) return -1100;
    if (hcp <= 6) return -1000;
    if (hcp <= 7) return -900;
    if (hcp <= 8) return -700;
    if (hcp <= 9) return -600;
    if (hcp <= 10) return -490;
    if (hcp <= 11) return -460;
    if (hcp <= 12) return -430;
    if (hcp <= 13) return -400;
    if (hcp <= 14) return -350;
    if (hcp <= 15) return -300;
    if (hcp <= 16) return -200;
    if (hcp <= 17) return -110;
    if (hcp <= 18) return -70;
    if (hcp <= 19) return -50;
    if (hcp <= 20) return 0;
    if (hcp <= 21) return 50;
    if (hcp <= 22) return 70;
    if (hcp <= 23) return 110;
    if (hcp <= 24) return 200;
    if (hcp <= 25) return 300;
    if (hcp <= 26) return 350;
    if (hcp <= 27) return 400;
    if (hcp <= 28) return 430;
    if (hcp <= 29) return 460;
    if (hcp <= 30) return 490;
    if (hcp <= 31) return 600;
    if (hcp <= 32) return 700;
    if (hcp <= 33) return 900;
    if (hcp <= 34) return 1000;
    if (hcp <= 35) return 1100;
    if (hcp <= 36) return 1200;
    return 1300;
  } else {
    // Уязвими зони (пример)
    if (hcp <= 20) return 0;
    if (hcp <= 21) return 50;
    if (hcp <= 22) return 70;
    if (hcp <= 23) return 110;
    if (hcp <= 24) return 290;
    if (hcp <= 25) return 440;
    if (hcp <= 26) return 520;
    if (hcp <= 27) return 600;
    if (hcp <= 28) return 630;
    if (hcp <= 29) return 660;
    if (hcp <= 30) return 690;
    if (hcp <= 31) return 900;
    if (hcp <= 32) return 1050;
    if (hcp <= 33) return 1350;
    if (hcp <= 34) return 1500;
    if (hcp <= 35) return 1650;
    if (hcp <= 36) return 1800;
    return 1950;
  }
}