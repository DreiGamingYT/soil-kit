class SoilLogicService {

  int score(String n, String p, String k){

    int value(String level){
      switch(level){
        case "HIGH": return 3;
        case "MEDIUM": return 2;
        case "LOW": return 1;
        default: return 0;
      }
    }

    return value(n) + value(p) + value(k);
  }

  String healthLabel(int score){
    if(score >= 8) return "HEALTHY";
    if(score >= 5) return "MODERATE";
    return "POOR";
  }

  List<String> recommendation(String n, String p, String k){

    List<String> rec = [];

    if(n == "LOW") rec.add("Apply Nitrogen-rich fertilizer (Urea / Compost)");
    if(p == "LOW") rec.add("Apply Phosphorus fertilizer (Bone meal / DAP)");
    if(k == "LOW") rec.add("Apply Potassium fertilizer (Muriate of Potash)");

    if(rec.isEmpty){
      rec.add("Soil is well-balanced");
    }

    return rec;
  }
}