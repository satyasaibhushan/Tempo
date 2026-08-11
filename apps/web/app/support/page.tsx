import type { Metadata } from "next";

import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Support · Tempo",
  description: "Get help with Tempo on web, iPhone, Mac, and widgets.",
};

export default function SupportPage() {
  return (
    <LegalPage
      eyebrow="Support / direct line"
      title="Let’s get your clock moving."
      introduction="Tempo is supported directly by Sai Bhushan. Include the device, app version, and what you expected to happen so the problem can be reproduced quickly."
    >
      <section>
        <h2>01. Contact</h2>
        <p className="mt-4">
          Email <a className="underline" href="mailto:satyasaibhushan@gmail.com">satyasaibhushan@gmail.com</a> for account, synchronization, timer, widget, privacy, or accessibility help.
        </p>
      </section>

      <section>
        <h2>02. Useful details</h2>
        <ul className="mt-4">
          <li>Whether the issue is on web, iPhone, Mac, or a widget.</li>
          <li>Your device model and operating-system version.</li>
          <li>The Tempo version and build number shown by the installed app.</li>
          <li>The steps immediately before the problem and any visible message.</li>
        </ul>
      </section>

      <section>
        <h2>03. Account deletion</h2>
        <p className="mt-4">
          Open Setup while signed in and choose Delete account. If you cannot
          access the app, email from the address associated with the account for
          assistance.
        </p>
      </section>

      <section>
        <h2>04. Response</h2>
        <p className="mt-4">
          Support requests are reviewed directly. Security or privacy concerns
          are prioritized; routine product questions are answered as soon as
          practical.
        </p>
      </section>
    </LegalPage>
  );
}
