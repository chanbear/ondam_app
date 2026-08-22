// Guardian 알림 전송 — analyze-message와 analyze-document가 함께 쓰는
// 공유 로직(ONDAM 2.0 요구사항 18: "문자 분석에서 이미 사용 중인 Guardian
// 알림 구조와 최대한 일관되게 구현"). 원래 analyze-message/index.ts 안에
// 있던 로직을 그대로 뽑아냈다 — 동작을 바꾸지 않았다.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { RiskLevel } from "./risk_floor.ts";

type ServiceClient = ReturnType<typeof createClient>;

// ONDAM 2.0 요구사항 18/27 — 위험도(caution/dangerous) 기반 알림 정책은
// 절대 좁히지 않는다. "정해진 기한이 있는 내용"([hasImportantDates])이라는
// 독립적인 조건을 OR로 추가할 뿐이다 — 둘 중 하나만 충족해도 보호자에게
// 알린다. safe + importantDates 없음은 여전히 알리지 않는다(기존 정책
// 그대로).
export function shouldNotifyGuardians(
  riskLevel: RiskLevel,
  hasImportantDates: boolean,
): boolean {
  return riskLevel === "caution" || riskLevel === "dangerous" ||
    hasImportantDates;
}

// guardian_links(accepted)를 조회해 각 보호자에게 send-notification을
// 호출한다. 실패해도 예외를 던지지 않는다 — 호출부(분석 결과 반환)를
// 절대 막지 않기 위해서다(요구사항 18: "Guardian 알림 실패 때문에 분석
// 전체가 실패하는 구조로 만들지 않는다").
export async function notifyGuardians(params: {
  serviceClient: ServiceClient;
  elderId: string;
  supabaseUrl: string;
  anonKey: string;
  authorization: string;
  notificationType: string;
  payload: Record<string, unknown>;
}): Promise<number> {
  try {
    const { data: links, error: linksError } = await params.serviceClient
      .from("guardian_links")
      .select("guardian_id")
      .eq("elder_id", params.elderId)
      .eq("status", "accepted");

    if (linksError || !links || links.length === 0) return 0;

    const results = await Promise.all(
      (links as { guardian_id: string }[]).map(async (link) => {
        try {
          const res = await fetch(
            `${params.supabaseUrl}/functions/v1/send-notification`,
            {
              method: "POST",
              headers: {
                "content-type": "application/json",
                "Authorization": params.authorization,
                "apikey": params.anonKey,
              },
              body: JSON.stringify({
                targetUserId: link.guardian_id,
                type: params.notificationType,
                payload: params.payload,
                sentVia: "push",
              }),
            },
          );
          return res.ok;
        } catch {
          return false;
        }
      }),
    );
    return results.filter(Boolean).length;
  } catch (e) {
    // 네트워크 등 예상치 못한 실패도 분석 결과 반환은 막지 않는다 — 서버
    // 로그로만 남긴다(비밀 정보 없음, 로그해도 안전).
    console.error("guardian_notify: notifyGuardians threw", e);
    return 0;
  }
}
