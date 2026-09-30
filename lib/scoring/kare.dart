import '../models/enums.dart';

/// Връща задължението в точки според HCP и уязвимост.
int getCommitment(int hcp, bool isVulnerable) {
  if (!isVulnerable) {
    // Неуязвими
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
    // Уязвими
    if (hcp <= 3) return -2000;
    if (hcp <= 4) return -1800;
    if (hcp <= 5) return -1650;
    if (hcp <= 6) return -1500;
    if (hcp <= 7) return -1350;
    if (hcp <= 8) return -1050;
    if (hcp <= 9) return -900;
    if (hcp <= 10) return -690;
    if (hcp <= 11) return -660;
    if (hcp <= 12) return -630;
    if (hcp <= 13) return -600;
    if (hcp <= 14) return -520;
    if (hcp <= 15) return -440;
    if (hcp <= 16) return -290;
    if (hcp <= 17) return -110;
    if (hcp <= 18) return -70;
    if (hcp <= 19) return -50;
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

/// Връща задължението за конкретна страна (NS или EW).
///
/// [nsHcp] – HCP на NS (винаги се въвежда за NS в приложението).
/// [zone] – зоната на борда.
/// [forNS] – true за NS, false за EW.
int getCommitmentForSide(int nsHcp, Zones zone, bool forNS) {
  final int hcp;
  final bool isVulnerable;

  if (forNS) {
    hcp = nsHcp;
    isVulnerable = (zone == Zones.ns || zone == Zones.all);
  } else {
    hcp = 40 - nsHcp;
    isVulnerable = (zone == Zones.ew || zone == Zones.all);
  }

  return getCommitment(hcp, isVulnerable);
}