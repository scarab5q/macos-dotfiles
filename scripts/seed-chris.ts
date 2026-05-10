/* eslint-disable no-console */

/**
 * Seed chris14@nsafe.com — a fully verified PRO user with real account data.
 *
 * Recreates the user from a production-like dump into both TMS and MVP databases
 * with ACTIVE banking accounts, completed onboarding, external provider entries,
 * and all feature flags needed for payouts.
 *
 * Usage:
 *   cd apps/backend
 *   doppler run -- pnpm exec tsx scripts/seed-chris.ts
 */

import "dotenv/config";
import {
  PrismaClient,
  Currency,
  UserStatus,
  BankingProviderEnum,
  ExternalProviderEnum,
  AccountStatus,
  Visibility,
  ProductType,
  Frequency,
  IdentificationType,
  IdentificationKycCategory,
  IdentificationProvider,
} from "@nsave/arrow-db";
import { MvpPrismaClient, OnboardingStage } from "@nsave/arq-db";
import { Decimal } from "@nsave/arrow-db";
import { encrypt } from "crypto-js/aes";
import { lib as CryptoLib, SHA256 } from "crypto-js";
import * as bcrypt from "bcrypt";

const prisma = new PrismaClient();
const mvpPrisma = new MvpPrismaClient();

// ── User constants ──────────────────────────────────────────────────────
const USER_ID = "c3b69d31-2700-4aac-9a88-c4c8496ec064";
const EMAIL = "chris14@nsafe.com";
const PHONE = "+880 1870 479383";
const FIRST_NAME = "Christopher William";
const LAST_NAME = "-";
const BIRTH_DATE = new Date("1989-11-16");
const NATIONALITIES = ["GB", "AE"];
const DEFAULT_PASSCODE = "1234";
const DEFAULT_PASSWORD = "Password!1";

// ── Banking accounts ────────────────────────────────────────────────────
const GBP_ACCOUNT_ID = "76d63d74-ba3b-4533-9666-f215ec6be818";
const GBP_EXTERNAL_ID = "537bc6ff-0549-488d-935b-3d6d6e3cb2ad";
const USD_ACCOUNT_ID = "8896046a-d414-4c2d-8aeb-cf2d81de6a05";
const USD_EXTERNAL_ID = "fd646523-bbc6-4c61-b7dc-7b6d2c0e4143";

// ── External provider IDs ───────────────────────────────────────────────
const KEEL_EXTERNAL_USER_ID = "fe1c8737-d4f2-48e8-b860-33245a49df49";
const FIN_EXTERNAL_USER_ID = "149c48e6-1a7f-436b-b1d9-4a8b186cccd0";
const VEEM_EXTERNAL_USER_ID = "47da82bd-eb43-4283-92f8-c24a700ed1f0";

function requireEnv(name: string): string {
  const val = process.env[name];
  if (!val) throw new Error(`${name} is not set.`);
  return val;
}

async function ensurePricingTiers() {
  for (const name of ["FREE", "PRO"]) {
    await prisma.pricing.upsert({
      where: { name },
      create: { name },
      update: {},
    });
    await mvpPrisma.pricing.upsert({
      where: { name },
      create: { name },
      update: {},
    });
  }
  const products = [
    ProductType.MEMBERSHIP,
    ProductType.CARD,
    ProductType.TRANSACTION,
  ];
  for (const type of products) {
    await prisma.product.upsert({
      where: { type },
      create: { type },
      update: {},
    });
  }
  const pricingProducts = [
    {
      pricingName: "FREE",
      productType: ProductType.MEMBERSHIP,
      amount: "0.00",
      frequency: Frequency.ONCE,
    },
    {
      pricingName: "FREE",
      productType: ProductType.CARD,
      amount: "35.00",
      frequency: Frequency.ONCE,
    },
    {
      pricingName: "FREE",
      productType: ProductType.TRANSACTION,
      amount: "0.00",
      frequency: Frequency.ONCE,
    },
    {
      pricingName: "PRO",
      productType: ProductType.MEMBERSHIP,
      amount: "4.99",
      frequency: Frequency.MONTHLY,
    },
    {
      pricingName: "PRO",
      productType: ProductType.CARD,
      amount: "0.00",
      frequency: Frequency.ONCE,
    },
    {
      pricingName: "PRO",
      productType: ProductType.TRANSACTION,
      amount: "0.00",
      frequency: Frequency.ONCE,
    },
  ];
  for (const pp of pricingProducts) {
    await prisma.pricingOnProduct.upsert({
      where: {
        pricingName_productType: {
          pricingName: pp.pricingName,
          productType: pp.productType,
        },
      },
      create: pp,
      update: { amount: pp.amount, frequency: pp.frequency },
    });
  }
}

async function cleanExisting() {
  console.log("Cleaning up existing chris14 data...");
  // Delete in dependency order — cascade handles most, but be explicit for safety
  await mvpPrisma.autoDocumentCheck.deleteMany({ where: { userId: USER_ID } });
  await prisma.user.deleteMany({ where: { id: USER_ID } });
  await prisma.user.deleteMany({ where: { email: EMAIL } });
  await mvpPrisma.user.deleteMany({ where: { id: USER_ID } });
  await mvpPrisma.user.deleteMany({ where: { email: EMAIL } });
  console.log("  Done.\n");
}

async function seedTmsUser(encryptedPasscode: string) {
  console.log("Creating TMS user...");
  await prisma.user.create({
    data: {
      id: USER_ID,
      firstName: FIRST_NAME,
      lastName: LAST_NAME,
      email: EMAIL,
      phone: PHONE,
      status: UserStatus.ACTIVE,
      currencies: [Currency.GBP, Currency.USD],
      pricing: { connect: { name: "PRO" } },
      passcode: encryptedPasscode,
      kyc_verified: true,
      kyc_id: "d8dc4c9f-f092-4f16-b48b-1f1982706716",
      kyc_user_key: "ea6eb26d-7b3b-4368-b4b6-c1c512656a9a",
      twilioPhoneVerified: true,
      twilioEmailVerified: false,
      nationalities: NATIONALITIES,
      birthDate: BIRTH_DATE,
      ntag: "chris",
      discoverableByNtag: true,
      behavior_added: true,
      priority: 2,
      // Referral code
      referral_code: { create: { code: "HVALcn", usageCount: 0 } },
      // External provider entries (KEEL, FIN, VEEM)
      external_users: {
        create: [
          {
            external_user_id: KEEL_EXTERNAL_USER_ID,
            external_blob: { id: KEEL_EXTERNAL_USER_ID },
            provider: ExternalProviderEnum.KEEL,
            status: UserStatus.ACTIVE,
          },
          {
            external_user_id: FIN_EXTERNAL_USER_ID,
            external_blob: {
              purposeId: "2",
              occupationId: "2",
              sourceOfFundsId: "3",
            },
            provider: ExternalProviderEnum.FIN,
            status: UserStatus.ACTIVE,
            tnc_accepted_at: new Date("2026-02-03T13:52:22.257Z"),
            tnc_id: "not applicable",
          },
          {
            external_user_id: VEEM_EXTERNAL_USER_ID,
            external_blob: { seeded: true },
            provider: ExternalProviderEnum.VEEM,
            status: UserStatus.ACTIVE,
            tnc_accepted_at: new Date("2025-10-28T15:08:48.431Z"),
          },
        ],
      },
      // Banking accounts — GBP and USD
      banking_accounts: {
        create: [
          {
            id: GBP_ACCOUNT_ID,
            external_account_id: GBP_EXTERNAL_ID,
            currency: Currency.GBP,
            provider: BankingProviderEnum.KEEL,
            account_status: AccountStatus.ACTIVE,
            visibility: Visibility.VISIBLE,
            balance: new Decimal("773.04"),
            available_balance: new Decimal("629.87"),
            bank_account_number: "00215232",
            sort_code: "040972",
            swift_code: "XBCAGB23",
            iban: "GB17CLRB04097200215232",
            censored_account_number: "5232",
            bank_name: "Frost Money Ltd",
            bank_address:
              "Fortunata House, 1st Floor 15 Wellington Road, Manchester, M30 0DR",
            jurisdiction: "UK",
            internal_trust_level: 1,
          },
          {
            id: USD_ACCOUNT_ID,
            external_account_id: USD_EXTERNAL_ID,
            currency: Currency.USD,
            provider: BankingProviderEnum.KEEL,
            account_status: AccountStatus.ACTIVE,
            visibility: Visibility.VISIBLE,
            balance: new Decimal("3571.23"),
            available_balance: new Decimal("2919.06"),
            bank_account_number: "09553568",
            sort_code: "042812",
            swift_code: "CLRBGB22XXX",
            iban: "GB17CLRB04281209553568",
            censored_account_number: "1684",
            bank_name: "Frost Money Ltd",
            bank_address:
              "Fortunata House, 1st Floor 15 Wellington Road, Manchester, M30 0DR",
            jurisdiction: "UK",
            internal_trust_level: 1,
          },
        ],
      },
      // Membership payment
      products: {
        create: {
          productType: ProductType.MEMBERSHIP,
          nextPayment: new Date("2026-03-01"),
          lastPayment: new Date("2026-01-29"),
        },
      },
      // Address
      address: {
        create: {
          street1: "123 street",
          postalCode: "1214",
          city: "Dhaka",
          country: "BD",
          pinLongitude: -122.083922,
          pinLatitude: 37.4220936,
          ipAddress: "192.168.65.1",
          subdivision: "13",
          validated: true,
        },
      },
      // Billing address
      billing_address: {
        create: {
          street1: "18 flack avenue",
          street2: "",
          postalCode: "SE57HE",
          city: "London",
          country: "GB",
        },
      },
      // Identification — no Strac tokens (they don't work locally)
      identification: {
        create: {
          id: `chris-id-${USER_ID}`,
          issueDate: new Date("2025-03-14"),
          issueCountry: "PK",
          nationality: "BD",
          birthDateOnDoc: BIRTH_DATE,
          type: IdentificationType.ID_CARD,
          kycCategory: IdentificationKycCategory.DOC_SCAN_N_SELFIE,
          provider: IdentificationProvider.AUTHOLOGIC,
        },
      },
      // User settings
      user_setting: {
        create: {
          osName: "android",
          osVersion: "sdk_gphone64_arm64",
          appVersion: "999.0.0",
          notificationsEnabled: false,
          lastLogin: new Date(),
          betaEnabled: true,
          isInternal: false,
        },
      },
      // Onboarding
      user_onboarding: {
        create: {
          onboarding_stage: "ADD_REFERRAL_CODE" as any,
          kycUserKey: "ea6eb26d-7b3b-4368-b4b6-c1c512656a9a",
          kycVerified: true,
          kycTriedCtr: 1,
          kycSuccessCtr: 1,
          kycStatus: "NOT_STARTED" as any,
          behaviorAdded: true,
          tncAccepted: true,
          tncAcceptedAt: new Date("2025-05-27T15:16:17.358Z"),
          submittedAt: new Date("2025-05-27T15:17:00.442Z"),
        },
      },
      // Risk
      risk: {
        create: {
          complyadvantage_clear: true,
          complyadvantage_ref: "1b5e452a-5ee4-42be-8248-e46357066c34",
          pep_status: "NOT_CHECKED" as any,
          sanction_screening: "NOT_CHECKED" as any,
          adverse_media: "NOT_CHECKED" as any,
          mesh_workflow_id: "1b5e452a-5ee4-42be-8248-e46357066c34",
        },
      },
      // Behavior data
      behavior_data: {
        create: {
          employment_status: "EMPLOYED" as any,
          purpose: "DAILY_TRANSACTIONS" as any,
          volume: "GTE_3001" as any,
          source_of_funds: "SAVINGS" as any,
          monthly_income_threshold: "GTE_6001" as any,
          industry_risk: "NOT_HIGH_RISK" as any,
          industry: "ACCOUNTING" as any,
          occupation: "ACC" as any,
        },
      },
    },
  });
  console.log("  TMS user created.\n");
}

async function seedMvpUser(
  encryptedPasscode: string,
  passcodeLock: string,
  hashedPassword: string,
) {
  console.log("Creating MVP user...");
  await mvpPrisma.user.create({
    data: {
      id: USER_ID,
      first_name: FIRST_NAME,
      last_name: LAST_NAME,
      email: EMAIL,
      phone: PHONE,
      status: "ACTIVE" as any,
      currencies: ["GBP", "USD"] as any,
      pricing: { connect: { name: "PRO" } },
      passcode: encryptedPasscode,
      passcode_lock: passcodeLock,
      password: hashedPassword,
      twilio_phone_verified: true,
      twilio_email_verified: false,
      nationalities: NATIONALITIES as any,
      birth_date: BIRTH_DATE,
      ntag: "chris",
      discoverableByNtag: true,
      promo: "OTHER" as any,
      // Referral code
      referral_code: { create: { code: "HVALcn" } },
      // User settings
      user_setting: {
        create: {
          lastLogin: new Date(),
          appVersion: "999.0.0",
          betaEnabled: true,
        },
      },
      // Onboarding (completed)
      user_onboarding: {
        create: {
          onboarding_stage: OnboardingStage.DONE,
          kyc_user_key: "ea6eb26d-7b3b-4368-b4b6-c1c512656a9a",
          kyc_verified: true,
          kyc_tried_ctr: 1,
          kyc_success_ctr: 1,
          kyc_status: "PENDING" as any,
          behavior_added: true,
          tnc_accepted: true,
          tnc_accepted_at: new Date("2025-05-27T15:16:17.355Z"),
          submitted_at: new Date("2025-05-27T15:17:00.442Z"),
          documents: ["BANK_STATEMENT", "SOW_DOCUMENT", "OTHER"] as any,
        },
      },
      // Banking accounts (same IDs as TMS)
      banking_accounts: {
        create: [
          {
            id: GBP_ACCOUNT_ID,
            external_account_id: GBP_EXTERNAL_ID,
            currency: "GBP" as any,
            provider: "KEEL" as any,
            account_status: "ACTIVE" as any,
            visibility: "VISIBLE" as any,
            balance: new Decimal("773.04"),
            available_balance: new Decimal("629.87"),
            bank_account_number: "00215232",
            sort_code: "040972",
            swift_code: "XBCAGB23",
            iban: "GB17CLRB04097200215232",
            censored_account_number: "5232",
            bank_name: "Frost Money Ltd",
            bank_address:
              "Fortunata House, 1st Floor 15 Wellington Road, Manchester, M30 0DR",
            jurisdiction: "UK" as any,
            internal_trust_level: 1,
          },
          {
            id: USD_ACCOUNT_ID,
            external_account_id: USD_EXTERNAL_ID,
            currency: "USD" as any,
            provider: "KEEL" as any,
            account_status: "ACTIVE" as any,
            visibility: "VISIBLE" as any,
            balance: new Decimal("3571.23"),
            available_balance: new Decimal("2919.06"),
            bank_account_number: "09553568",
            sort_code: "042812",
            swift_code: "CLRBGB22XXX",
            iban: "GB17CLRB04281209553568",
            censored_account_number: "1684",
            bank_name: "Frost Money Ltd",
            bank_address:
              "Fortunata House, 1st Floor 15 Wellington Road, Manchester, M30 0DR",
            jurisdiction: "UK" as any,
            internal_trust_level: 1,
          },
        ],
      },
      // Address
      address: {
        create: {
          street_1: "123 street",
          postal_code: "1214",
          city: "Dhaka",
          country: "BD",
          pin_longitude: -122.083922,
          pin_latitude: 37.4220936,
          ip_address: "192.168.65.1",
          subdivision: "13",
          validated: true,
        },
      },
      // Billing address
      billing_address: {
        create: {
          street_1: "18 flack avenue",
          street_2: "",
          postal_code: "SE57HE",
          city: "London",
          country: "GB",
        },
      },
      // Identification — no Strac tokens
      identification: {
        create: {
          id: `chris-id-${USER_ID}`,
          issue_date: new Date("2025-03-14"),
          issue_country: "PK",
          nationality: "BD",
          birth_date_on_doc: BIRTH_DATE,
          type: "ID_CARD" as any,
          kyc_category: "DOC_SCAN_N_SELFIE" as any,
          provider: "AUTHOLOGIC" as any,
        },
      },
      // Membership payment
      products: {
        create: {
          next_payment: new Date("2026-03-01"),
          last_payment: new Date("2026-01-29"),
          product_type: "MEMBERSHIP" as any,
        },
      },
    },
  });
  console.log("  MVP user created.\n");
}

async function seedOnboardingCase() {
  // Approved onboarding case so the user isn't flagged
  console.log("Creating approved onboarding case...");
  await prisma.case.create({
    data: {
      type: "ONBOARDING" as any,
      user_id: USER_ID,
      status: "APPROVED" as any,
      open_reason: "USER_ONBOARDING" as any,
      close_reason: "FALSE_POSITIVE" as any,
      review_level: "ANALYST" as any,
    },
  });
  console.log("  Done.\n");
}

async function seedPoaAutoCheck() {
  // Completed POA auto-check so transfers aren't blocked by address validation
  console.log("Creating POA auto-check...");
  await mvpPrisma.autoDocumentCheck.create({
    data: {
      userId: USER_ID,
      autoAssessmentResponse: "Seeded POA - auto check deemed valid",
      autoAssessmentApproved: true,
      humanAssessmentApproved: true,
      status: "COMPLETED" as any,
      autoAssessmentStructuredResponse: {
        reasoning: "Valid POA seeded by seed-chris script",
        isValidDocument: true,
        comparisonResults: { nameMatch: "yes", addressMatch: "yes" },
        imageQualityChecks: { directCapture: true, completeDocument: true },
        recommendedAddress: {
          city: "Dhaka",
          street1: "123 street",
          street2: "",
          postalCode: "1214",
          countryCode: "BD",
          subdivisionCode: "13",
        },
        extractedInformation: {
          issuer: "GOV.BD",
          address: "123 street, Dhaka, 1214, BD",
          fullName: `${FIRST_NAME} ${LAST_NAME}`,
          issueDate: "2025-06-01",
        },
      },
    },
  });
  console.log("  Done.\n");
}

async function main() {
  console.log("Seeding chris14@nsafe.com...\n");

  const masrefPasscodeKey = requireEnv("MASREF_PASSCODE_ENCRYPTION_KEY");
  const encryptedPasscode = encrypt(
    DEFAULT_PASSCODE,
    masrefPasscodeKey,
  ).toString();
  const salt = CryptoLib.WordArray.random(16).toString();
  const passcodeLock = SHA256(salt + DEFAULT_PASSCODE).toString();
  const hashedPassword = await bcrypt.hash(DEFAULT_PASSWORD, 10);

  await ensurePricingTiers();
  await cleanExisting();
  await seedTmsUser(encryptedPasscode);
  await seedMvpUser(encryptedPasscode, passcodeLock, hashedPassword);
  await seedOnboardingCase();
  await seedPoaAutoCheck();

  console.log("=".repeat(60));
  console.log("SEED COMPLETED");
  console.log("=".repeat(60));
  console.log(`
User Details:
  ID:         ${USER_ID}
  Phone:      ${PHONE}
  Email:      ${EMAIL}
  Passcode:   ${DEFAULT_PASSCODE}
  Password:   ${DEFAULT_PASSWORD}
  Pricing:    PRO

Banking Accounts:
  GBP: ${GBP_ACCOUNT_ID} (IBAN: GB17CLRB04097200215232, bal: 773.04)
  USD: ${USD_ACCOUNT_ID} (IBAN: GB17CLRB04281209553568, bal: 3571.23)

External Providers:
  KEEL: ${KEEL_EXTERNAL_USER_ID}
  FIN:  ${FIN_EXTERNAL_USER_ID}
  VEEM: ${VEEM_EXTERNAL_USER_ID}
`);
}

main()
  .catch((e) => {
    console.error("Seed failed:", e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
    await mvpPrisma.$disconnect();
  });
