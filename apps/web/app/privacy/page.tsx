import type { Metadata } from "next";

import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = {
  title: "Privacy Policy · Tempo",
  description: "How Tempo collects, uses, and protects your information.",
};

export default function PrivacyPage() {
  return (
    <LegalPage
      eyebrow="Privacy / plain language"
      title="Your time stays yours."
      introduction="Tempo collects only what it needs to keep your account and timers synchronized. It does not sell personal information, serve advertising, or track you across other companies’ apps and websites."
    >
      <section>
        <h2>01. Information Tempo keeps</h2>
        <p className="mt-4">
          Tempo stores the information you provide and the records needed to
          deliver the service:
        </p>
        <ul className="mt-4">
          <li>Your name, email address, profile image, and account identifier.</li>
          <li>Your timers, time entries, notes, folders, labels, and preferences.</li>
          <li>Authentication and operational data needed to keep the service secure and synchronized.</li>
        </ul>
      </section>

      <section>
        <h2>02. How it is used</h2>
        <p className="mt-4">
          This information is used only to authenticate you, synchronize Tempo
          across web, iPhone, Mac, and widgets, provide support, prevent abuse,
          and maintain the reliability of the service.
        </p>
      </section>

      <section>
        <h2>03. Service providers</h2>
        <p className="mt-4">
          Auth0 processes sign-in and account identity. Convex stores and
          synchronizes application data. Hosting and delivery providers process
          limited technical data required to operate Tempo. These providers act
          only to deliver their services to Tempo.
        </p>
      </section>

      <section>
        <h2>04. Retention and deletion</h2>
        <p className="mt-4">
          Tempo keeps account data until you delete your account. You can start
          permanent deletion from Setup in the web, iPhone, or Mac app. Deletion
          removes the Tempo records associated with your account and your Auth0
          identity. You may also request help by email.
        </p>
      </section>

      <section>
        <h2>05. Your choices</h2>
        <p className="mt-4">
          You may review and update profile information from Setup, review your
          time records in the app, sign out at any time, or delete
          your account. Contact Sai Bhushan if you have a privacy question or
          need assistance exercising these choices.
        </p>
      </section>

      <section>
        <h2>06. Security and changes</h2>
        <p className="mt-4">
          Tempo uses encrypted network connections and access controls designed
          to protect your information. No system is perfectly secure. Material
          changes to this policy will be reflected on this page with a new
          effective date.
        </p>
      </section>
    </LegalPage>
  );
}
