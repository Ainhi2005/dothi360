import type { ReactNode } from 'react';
import { ChevronRight } from 'lucide-react';

export function PageHeader({
  title,
  parent,
  description,
  actions,
}: {
  title: string;
  parent?: string;
  description?: string;
  actions?: ReactNode;
}) {
  return (
    <header className="page-header">
      <div>
        <div className="breadcrumbs">
          <span>{parent ?? 'Điều hành'}</span>
          <ChevronRight size={13} />
          <strong>{title}</strong>
        </div>
        <h1>{title}</h1>
        {description && <p>{description}</p>}
      </div>
      {actions && <div className="page-actions">{actions}</div>}
    </header>
  );
}
