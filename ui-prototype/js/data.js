// Mock data only — no real user information. Shapes mirror ondam_models
// (AnalysisResult / RiskLevel / FeeStatistics-ish) enough for the prototype
// to look real, without being a 1:1 port of the Dart classes.
const ONDAM_DATA = {
  elders: [
    { id: "e1", name: "아버님", relation: "아버지", lastActive: "10분 전", risk: "caution" },
    { id: "e2", name: "어머님", relation: "어머니", lastActive: "2시간 전", risk: "safe" },
  ],

  documents: [
    { id: "d1", elderId: "e1", type: "고지서", title: "한국전력 전기요금 고지서", risk: "safe", date: "2026-08-25", amount: 87500, category: "전기요금", confidence: "높음" },
    { id: "d2", elderId: "e1", type: "고지서", title: "SK텔레콤 통신요금 고지서", risk: "safe", date: "2026-09-10", amount: 45300, category: "통신요금", confidence: "높음" },
    { id: "d3", elderId: "e1", type: "고지서", title: "OO아파트 관리비 고지서", risk: "safe", date: "2026-06-25", amount: 152000, category: "관리비", confidence: "보통" },
    { id: "d4", elderId: "e1", type: "안내문", title: "정체불명 투자 안내문", risk: "dangerous", date: "2026-08-18", amount: null, category: "기타", confidence: "높음" },
    { id: "d5", elderId: "e2", type: "고지서", title: "도시가스 요금 고지서", risk: "safe", date: "2026-08-20", amount: 38200, category: "가스요금", confidence: "높음" },
  ],

  messages: [
    { id: "m1", elderId: "e1", from: "010-****-2231", preview: "[Web발신] 고객님 명의로 개설된 계좌가 확인되어...", risk: "dangerous", date: "2026-08-18 14:12", reason: "금융/개인정보 요구" },
    { id: "m2", elderId: "e1", from: "우체국택배", preview: "[택배] 고객님의 상품이 배송 중입니다. 송장번호...", risk: "safe", date: "2026-08-18 09:03", reason: null },
    { id: "m3", elderId: "e1", from: "010-****-9087", preview: "안녕하세요, oo구청입니다. 지원금 신청이 확인되어...", risk: "caution", date: "2026-08-17 16:40", reason: "공공기관 사칭 의심" },
    { id: "m4", elderId: "e2", from: "국민건강보험공단", preview: "건강검진 대상자로 안내드립니다.", risk: "safe", date: "2026-08-16 10:20", reason: null },
  ],

  feeStats: {
    total: 284800, avg: 94933, max: 152000, min: 45300, count: 3,
    monthly: [
      { m: "3월", v: 210000 }, { m: "4월", v: 198000 }, { m: "5월", v: 225000 },
      { m: "6월", v: 152000 }, { m: "7월", v: 96000 }, { m: "8월", v: 87500 },
    ],
    yearly: [
      { y: "2023", v: 2340000 }, { y: "2024", v: 2510000 }, { y: "2025", v: 2280000 }, { y: "2026", v: 1980000 },
    ],
    lastMonthDelta: -12500,
  },

  notifications: [
    { id: "n1", elderId: "e1", kind: "dangerous", title: "위험 문자가 감지됐어요", desc: "아버님께 온 문자에서 금융 정보 요구가 확인됐어요.", ts: "14:12", read: false },
    { id: "n2", elderId: "e1", kind: "caution", title: "주의가 필요한 문자예요", desc: "공공기관을 사칭하는 문자로 의심돼요.", ts: "어제", read: false },
    { id: "n3", elderId: "e2", kind: "safe", title: "새 고지서가 등록됐어요", desc: "도시가스 요금 고지서가 확인됐어요.", ts: "2일 전", read: true },
  ],

  welfareCenters: [
    { id: "w1", name: "행복경로당", dist: "320m", addr: "서울시 OO구 OO로 12", phone: "02-1234-5678", open: true },
    { id: "w2", name: "은빛노인복지관", dist: "540m", addr: "서울시 OO구 OO로 45", phone: "02-2345-6789", open: true },
    { id: "w3", name: "정겨운경로당", dist: "890m", addr: "서울시 OO구 OO로 88", phone: "02-3456-7890", open: false },
  ],
};

function ondamRisk(level) {
  return { safe: { label: "안전", color: "success", icon: "check_circle" }, caution: { label: "주의", color: "warning", icon: "error" }, dangerous: { label: "위험 감지", color: "danger", icon: "warning" } }[level];
}
function won(n) { return n == null ? "-" : n.toLocaleString("ko-KR") + "원"; }
