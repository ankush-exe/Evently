-- CreateEnum
CREATE TYPE "OrganizerApplicationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateTable
CREATE TABLE "OrganizerApplication" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "OrganizerApplicationStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OrganizerApplication_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OrganizerProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OrganizerProfile_pkey" PRIMARY KEY ("id")
);

-- Preserve existing event ownership by creating one organizer profile per legacy event owner.
ALTER TABLE "Event" ADD COLUMN "organizerProfileId" TEXT;

INSERT INTO "OrganizerProfile" ("id", "userId", "createdAt", "updatedAt")
SELECT md5('evently-organizer-profile:' || "organizerId"), "organizerId", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
FROM "Event"
GROUP BY "organizerId";

UPDATE "Event"
SET "organizerProfileId" = md5('evently-organizer-profile:' || "organizerId");

ALTER TABLE "Event" ALTER COLUMN "organizerProfileId" SET NOT NULL;

-- Replace the direct User ownership relation with OrganizerProfile ownership.
ALTER TABLE "Event" DROP CONSTRAINT "Event_organizerId_fkey";
DROP INDEX "Event_organizerId_idx";
ALTER TABLE "Event" DROP COLUMN "organizerId";

-- CreateIndex
CREATE UNIQUE INDEX "OrganizerProfile_userId_key" ON "OrganizerProfile"("userId");
CREATE INDEX "OrganizerApplication_userId_status_createdAt_idx" ON "OrganizerApplication"("userId", "status", "createdAt");
CREATE INDEX "OrganizerApplication_status_createdAt_idx" ON "OrganizerApplication"("status", "createdAt");
CREATE INDEX "Event_organizerProfileId_idx" ON "Event"("organizerProfileId");

-- AddForeignKey
ALTER TABLE "OrganizerApplication" ADD CONSTRAINT "OrganizerApplication_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "OrganizerProfile" ADD CONSTRAINT "OrganizerProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Event" ADD CONSTRAINT "Event_organizerProfileId_fkey" FOREIGN KEY ("organizerProfileId") REFERENCES "OrganizerProfile"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
