export const ROLES = {
  CITIZEN: 'CITIZEN',
  OFFICER: 'OFFICER',
  ADMIN: 'ADMIN',
} as const;

export type RoleType = keyof typeof ROLES;
