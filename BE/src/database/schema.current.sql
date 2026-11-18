--
-- PostgreSQL database dump
--

\restrict 9JFUnTut91brATUey3H8isyz7ychr3cKuPtIY43t5AHa0bMI3iJBNOmAfiB9Jpc

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_feedbacks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_feedbacks (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    report_id uuid NOT NULL,
    actor_id uuid,
    source character varying(30) NOT NULL,
    ai_incident_type character varying(200),
    confirmed_incident_type_id uuid,
    ai_severity smallint,
    confirmed_severity smallint,
    decision character varying(30) NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ai_feedbacks_source_check CHECK (((source)::text = ANY ((ARRAY['CITIZEN_CONFIRMATION'::character varying, 'ADMIN_REVIEW'::character varying])::text[])))
);


--
-- Name: algorithm_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.algorithm_configs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    config_key character varying(100) NOT NULL,
    config_value jsonb NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    description text,
    is_active boolean DEFAULT false NOT NULL,
    updated_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_algorithm_configs_version CHECK ((version >= 1))
);


--
-- Name: areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.areas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    department_id uuid NOT NULL,
    name character varying(200) NOT NULL,
    geom public.geometry(Polygon,4326) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_areas_not_empty CHECK ((NOT public.st_isempty(geom))),
    CONSTRAINT ck_areas_valid_geometry CHECK (public.st_isvalid(geom))
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id bigint NOT NULL,
    user_id uuid,
    action character varying(100) NOT NULL,
    entity_type character varying(50),
    entity_id uuid,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: citizen_feedback_upvotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.citizen_feedback_upvotes (
    feedback_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: citizen_feedbacks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.citizen_feedbacks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    title character varying(250) NOT NULL,
    content text NOT NULL,
    category character varying(50) DEFAULT 'GENERAL'::character varying NOT NULL,
    location_name character varying(255),
    location public.geography(Point,4326),
    upvotes integer DEFAULT 0 NOT NULL,
    status character varying(30) DEFAULT 'PENDING'::character varying NOT NULL,
    admin_response text,
    responded_at timestamp with time zone,
    responded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_feedback_category CHECK (((category)::text = ANY ((ARRAY['TRAFFIC'::character varying, 'GREENERY'::character varying, 'LIGHTING'::character varying, 'DRAINAGE'::character varying, 'ENVIRONMENT'::character varying, 'GENERAL'::character varying])::text[]))),
    CONSTRAINT ck_feedback_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'ACCEPTED'::character varying, 'REJECTED'::character varying])::text[])))
);


--
-- Name: department_incident_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department_incident_types (
    department_id uuid NOT NULL,
    incident_type_id uuid NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(200) NOT NULL,
    address text,
    location public.geography(Point,4326),
    phone character varying(20),
    email public.citext,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: device_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.device_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    platform character varying(20) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_used_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_device_tokens_platform CHECK (((platform)::text = ANY ((ARRAY['ANDROID'::character varying, 'IOS'::character varying, 'WEB'::character varying])::text[])))
);


--
-- Name: emergency_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emergency_contacts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(160) NOT NULL,
    phone_number character varying(50) NOT NULL,
    category character varying(60) DEFAULT 'NATIONAL'::character varying NOT NULL,
    description character varying(300) NOT NULL,
    icon character varying(40) DEFAULT 'phone'::character varying NOT NULL,
    accent character varying(20) DEFAULT 'primary'::character varying NOT NULL,
    is_hotline boolean DEFAULT false NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    operating_hours character varying(60) DEFAULT '24/7'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: emergency_guides; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emergency_guides (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    code character varying(60) NOT NULL,
    title character varying(160) NOT NULL,
    summary character varying(300) NOT NULL,
    icon character varying(40) DEFAULT 'warning'::character varying NOT NULL,
    accent character varying(20) DEFAULT 'danger'::character varying NOT NULL,
    do_now jsonb DEFAULT '[]'::jsonb NOT NULL,
    avoid jsonb DEFAULT '[]'::jsonb NOT NULL,
    phone_numbers jsonb DEFAULT '[]'::jsonb NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: incident_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    incident_id uuid NOT NULL,
    department_id uuid NOT NULL,
    assigned_by uuid,
    accepted_by uuid,
    assignment_method character varying(30) NOT NULL,
    reason text,
    workload_at_assignment integer,
    distance_m numeric(10,2),
    assigned_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    accepted_at timestamp with time zone,
    ended_at timestamp with time zone,
    rejected_by uuid,
    rejection_code character varying(40),
    rejection_reason text,
    rejected_at timestamp with time zone,
    assigned_officer_id uuid,
    CONSTRAINT ck_assignments_acceptance CHECK ((((accepted_by IS NULL) AND (accepted_at IS NULL)) OR ((accepted_by IS NOT NULL) AND (accepted_at IS NOT NULL)))),
    CONSTRAINT ck_assignments_acceptance_time CHECK (((accepted_at IS NULL) OR (accepted_at >= assigned_at))),
    CONSTRAINT ck_assignments_distance CHECK (((distance_m IS NULL) OR (distance_m >= (0)::numeric))),
    CONSTRAINT ck_assignments_method CHECK (((assignment_method)::text = ANY ((ARRAY['AREA_CONTAINMENT'::character varying, 'NEAREST_RADIUS'::character varying, 'MANUAL'::character varying, 'AI_SUGGESTED'::character varying])::text[]))),
    CONSTRAINT ck_assignments_period CHECK (((ended_at IS NULL) OR (ended_at >= assigned_at))),
    CONSTRAINT ck_assignments_workload CHECK (((workload_at_assignment IS NULL) OR (workload_at_assignment >= 0)))
);


--
-- Name: incident_checklist_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_checklist_results (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    incident_id uuid NOT NULL,
    checklist_item_id uuid NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    note text,
    completed_by uuid,
    completed_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: incident_media; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_media (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    incident_id uuid NOT NULL,
    report_id uuid,
    update_id uuid,
    uploaded_by uuid NOT NULL,
    media_type character varying(20) NOT NULL,
    storage_key text NOT NULL,
    file_url text NOT NULL,
    mime_type character varying(100) NOT NULL,
    file_size bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_incident_media_context CHECK ((NOT ((report_id IS NOT NULL) AND (update_id IS NOT NULL)))),
    CONSTRAINT ck_incident_media_size CHECK ((file_size > 0)),
    CONSTRAINT ck_incident_media_type CHECK (((media_type)::text = ANY ((ARRAY['IMAGE'::character varying, 'VIDEO'::character varying])::text[])))
);


--
-- Name: incident_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    incident_id uuid NOT NULL,
    reporter_id uuid NOT NULL,
    description text NOT NULL,
    reported_location public.geography(Point,4326) NOT NULL,
    reported_severity smallint,
    duplicate_distance_m numeric(10,2),
    duplicate_time_minutes numeric(10,2),
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ai_analysis jsonb,
    requires_manual_review boolean DEFAULT false NOT NULL,
    duplicate_score numeric(5,4),
    duplicate_evidence jsonb,
    reported_address text,
    location_source character varying(20) DEFAULT 'GPS'::character varying NOT NULL,
    CONSTRAINT ck_incident_reports_duplicate_distance CHECK (((duplicate_distance_m IS NULL) OR (duplicate_distance_m >= (0)::numeric))),
    CONSTRAINT ck_incident_reports_duplicate_time CHECK (((duplicate_time_minutes IS NULL) OR (duplicate_time_minutes >= (0)::numeric))),
    CONSTRAINT ck_incident_reports_severity CHECK (((reported_severity IS NULL) OR ((reported_severity >= 1) AND (reported_severity <= 5)))),
    CONSTRAINT ck_report_location_source CHECK (((location_source)::text = ANY ((ARRAY['GPS'::character varying, 'MAP'::character varying, 'SEARCH'::character varying])::text[])))
);


--
-- Name: incident_type_checklist_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_type_checklist_items (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    incident_type_id uuid NOT NULL,
    title character varying(250) NOT NULL,
    description text,
    is_required boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: incident_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    type_priority_level smallint DEFAULT 3 NOT NULL,
    default_severity smallint DEFAULT 3 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_incident_types_priority CHECK (((type_priority_level >= 1) AND (type_priority_level <= 5))),
    CONSTRAINT ck_incident_types_severity CHECK (((default_severity >= 1) AND (default_severity <= 5)))
);


--
-- Name: incident_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incident_updates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    incident_id uuid NOT NULL,
    updated_by uuid NOT NULL,
    old_status character varying(30),
    new_status character varying(30),
    note text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    progress_percent smallint,
    estimated_completion_at timestamp with time zone,
    blocker text,
    visibility character varying(20) DEFAULT 'PUBLIC'::character varying NOT NULL,
    CONSTRAINT ck_incident_updates_content CHECK (((old_status IS NOT NULL) OR (new_status IS NOT NULL) OR (note IS NOT NULL))),
    CONSTRAINT ck_incident_updates_new_status CHECK (((new_status IS NULL) OR ((new_status)::text = ANY ((ARRAY['PENDING_ASSIGNMENT'::character varying, 'ASSIGNED'::character varying, 'ACCEPTED'::character varying, 'IN_PROGRESS'::character varying, 'PENDING_VERIFICATION'::character varying, 'RESOLVED'::character varying, 'REJECTED'::character varying, 'CANCELLED'::character varying])::text[])))),
    CONSTRAINT ck_incident_updates_old_status CHECK (((old_status IS NULL) OR ((old_status)::text = ANY ((ARRAY['PENDING_ASSIGNMENT'::character varying, 'ASSIGNED'::character varying, 'ACCEPTED'::character varying, 'IN_PROGRESS'::character varying, 'PENDING_VERIFICATION'::character varying, 'RESOLVED'::character varying, 'REJECTED'::character varying, 'CANCELLED'::character varying])::text[])))),
    CONSTRAINT ck_update_progress CHECK (((progress_percent IS NULL) OR ((progress_percent >= 0) AND (progress_percent <= 100)))),
    CONSTRAINT ck_update_visibility CHECK (((visibility)::text = ANY ((ARRAY['PUBLIC'::character varying, 'INTERNAL'::character varying])::text[])))
);


--
-- Name: incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incidents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    incident_type_id uuid NOT NULL,
    description text NOT NULL,
    location public.geography(Point,4326) NOT NULL,
    severity_level smallint NOT NULL,
    status character varying(30) DEFAULT 'PENDING_ASSIGNMENT'::character varying NOT NULL,
    priority_score numeric(5,2),
    priority_level character varying(20),
    report_count integer DEFAULT 1 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    resolved_at timestamp with time zone,
    ai_suggested_department_id uuid,
    ai_suggested_officer_id uuid,
    ai_suggestion_reason text,
    ai_suggestion_confidence numeric(4,2),
    CONSTRAINT ck_incidents_priority_level CHECK (((priority_level IS NULL) OR ((priority_level)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'EMERGENCY'::character varying])::text[])))),
    CONSTRAINT ck_incidents_priority_score CHECK (((priority_score IS NULL) OR ((priority_score >= (0)::numeric) AND (priority_score <= (100)::numeric)))),
    CONSTRAINT ck_incidents_report_count CHECK ((report_count >= 1)),
    CONSTRAINT ck_incidents_resolution CHECK (((((status)::text = 'RESOLVED'::text) AND (resolved_at IS NOT NULL)) OR (((status)::text <> 'RESOLVED'::text) AND (resolved_at IS NULL)))),
    CONSTRAINT ck_incidents_resolved_time CHECK (((resolved_at IS NULL) OR (resolved_at >= created_at))),
    CONSTRAINT ck_incidents_severity CHECK (((severity_level >= 1) AND (severity_level <= 5))),
    CONSTRAINT ck_incidents_status CHECK (((status)::text = ANY ((ARRAY['PENDING_ASSIGNMENT'::character varying, 'ASSIGNED'::character varying, 'ACCEPTED'::character varying, 'IN_PROGRESS'::character varying, 'PENDING_VERIFICATION'::character varying, 'RESOLVED'::character varying, 'REJECTED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    incident_id uuid,
    type character varying(50) NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    read_at timestamp with time zone,
    push_status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    push_attempts smallint DEFAULT 0 NOT NULL,
    push_sent_at timestamp with time zone,
    push_last_error text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_notifications_attempts CHECK ((push_attempts >= 0)),
    CONSTRAINT ck_notifications_push_status CHECK (((push_status)::text = ANY ((ARRAY['PENDING'::character varying, 'PROCESSING'::character varying, 'SENT'::character varying, 'FAILED'::character varying, 'SKIPPED'::character varying])::text[]))),
    CONSTRAINT ck_notifications_read CHECK ((((is_read = false) AND (read_at IS NULL)) OR ((is_read = true) AND (read_at IS NOT NULL)))),
    CONSTRAINT ck_notifications_read_time CHECK (((read_at IS NULL) OR (read_at >= created_at)))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    replaced_by_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT ck_refresh_tokens_expiry CHECK ((expires_at > created_at)),
    CONSTRAINT ck_refresh_tokens_revoked CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at)))
);


--
-- Name: user_interested_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_interested_areas (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    name character varying(80) NOT NULL,
    center public.geography(Point,4326) NOT NULL,
    radius_m integer DEFAULT 1000 NOT NULL,
    notifications_enabled boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_interested_area_radius CHECK (((radius_m >= 200) AND (radius_m <= 10000)))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    full_name character varying(150) NOT NULL,
    email public.citext NOT NULL,
    password_hash character varying(255) NOT NULL,
    phone character varying(20),
    role character varying(20) DEFAULT 'CITIZEN'::character varying NOT NULL,
    department_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    must_change_password boolean DEFAULT false NOT NULL,
    CONSTRAINT ck_users_department_by_role CHECK (((((role)::text = 'OFFICER'::text) AND (department_id IS NOT NULL)) OR (((role)::text = ANY ((ARRAY['CITIZEN'::character varying, 'ADMIN'::character varying])::text[])) AND (department_id IS NULL)))),
    CONSTRAINT ck_users_role CHECK (((role)::text = ANY ((ARRAY['CITIZEN'::character varying, 'OFFICER'::character varying, 'ADMIN'::character varying])::text[])))
);


--
-- Name: ai_feedbacks ai_feedbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_feedbacks
    ADD CONSTRAINT ai_feedbacks_pkey PRIMARY KEY (id);


--
-- Name: algorithm_configs algorithm_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.algorithm_configs
    ADD CONSTRAINT algorithm_configs_pkey PRIMARY KEY (id);


--
-- Name: areas areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: citizen_feedback_upvotes citizen_feedback_upvotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citizen_feedback_upvotes
    ADD CONSTRAINT citizen_feedback_upvotes_pkey PRIMARY KEY (feedback_id, user_id);


--
-- Name: citizen_feedbacks citizen_feedbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citizen_feedbacks
    ADD CONSTRAINT citizen_feedbacks_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: device_tokens device_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_pkey PRIMARY KEY (id);


--
-- Name: emergency_contacts emergency_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emergency_contacts
    ADD CONSTRAINT emergency_contacts_pkey PRIMARY KEY (id);


--
-- Name: emergency_guides emergency_guides_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emergency_guides
    ADD CONSTRAINT emergency_guides_code_key UNIQUE (code);


--
-- Name: emergency_guides emergency_guides_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emergency_guides
    ADD CONSTRAINT emergency_guides_pkey PRIMARY KEY (id);


--
-- Name: incident_assignments incident_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_assignments
    ADD CONSTRAINT incident_assignments_pkey PRIMARY KEY (id);


--
-- Name: incident_checklist_results incident_checklist_results_incident_id_checklist_item_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_checklist_results
    ADD CONSTRAINT incident_checklist_results_incident_id_checklist_item_id_key UNIQUE (incident_id, checklist_item_id);


--
-- Name: incident_checklist_results incident_checklist_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_checklist_results
    ADD CONSTRAINT incident_checklist_results_pkey PRIMARY KEY (id);


--
-- Name: incident_media incident_media_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_media
    ADD CONSTRAINT incident_media_pkey PRIMARY KEY (id);


--
-- Name: incident_reports incident_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_reports
    ADD CONSTRAINT incident_reports_pkey PRIMARY KEY (id);


--
-- Name: incident_type_checklist_items incident_type_checklist_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_type_checklist_items
    ADD CONSTRAINT incident_type_checklist_items_pkey PRIMARY KEY (id);


--
-- Name: incident_types incident_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_types
    ADD CONSTRAINT incident_types_pkey PRIMARY KEY (id);


--
-- Name: incident_updates incident_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_updates
    ADD CONSTRAINT incident_updates_pkey PRIMARY KEY (id);


--
-- Name: incidents incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: department_incident_types pk_department_incident_types; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_incident_types
    ADD CONSTRAINT pk_department_incident_types PRIMARY KEY (department_id, incident_type_id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: algorithm_configs uq_algorithm_configs_version; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.algorithm_configs
    ADD CONSTRAINT uq_algorithm_configs_version UNIQUE (config_key, version);


--
-- Name: areas uq_areas_department_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT uq_areas_department_name UNIQUE (department_id, name);


--
-- Name: departments uq_departments_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT uq_departments_code UNIQUE (code);


--
-- Name: departments uq_departments_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT uq_departments_name UNIQUE (name);


--
-- Name: device_tokens uq_device_tokens_token; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT uq_device_tokens_token UNIQUE (token);


--
-- Name: incident_media uq_incident_media_storage_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_media
    ADD CONSTRAINT uq_incident_media_storage_key UNIQUE (storage_key);


--
-- Name: incident_reports uq_incident_reports_incident_reporter; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_reports
    ADD CONSTRAINT uq_incident_reports_incident_reporter UNIQUE (incident_id, reporter_id);


--
-- Name: incident_types uq_incident_types_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_types
    ADD CONSTRAINT uq_incident_types_code UNIQUE (code);


--
-- Name: incident_types uq_incident_types_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_types
    ADD CONSTRAINT uq_incident_types_name UNIQUE (name);


--
-- Name: refresh_tokens uq_refresh_tokens_hash; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT uq_refresh_tokens_hash UNIQUE (token_hash);


--
-- Name: users uq_users_email; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uq_users_email UNIQUE (email);


--
-- Name: users uq_users_phone; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uq_users_phone UNIQUE (phone);


--
-- Name: user_interested_areas user_interested_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_interested_areas
    ADD CONSTRAINT user_interested_areas_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_ai_feedbacks_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ai_feedbacks_report ON public.ai_feedbacks USING btree (report_id, created_at DESC);


--
-- Name: idx_areas_department_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_areas_department_active ON public.areas USING btree (department_id) WHERE (is_active = true);


--
-- Name: idx_areas_geom_gist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_areas_geom_gist ON public.areas USING gist (geom);


--
-- Name: idx_assignments_department_current; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assignments_department_current ON public.incident_assignments USING btree (department_id, assigned_at) WHERE (ended_at IS NULL);


--
-- Name: idx_assignments_incident_history; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assignments_incident_history ON public.incident_assignments USING btree (incident_id, assigned_at DESC);


--
-- Name: idx_assignments_offered_officer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assignments_offered_officer ON public.incident_assignments USING btree (assigned_officer_id, assigned_at DESC) WHERE ((ended_at IS NULL) AND (accepted_by IS NULL));


--
-- Name: idx_assignments_rejected_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assignments_rejected_at ON public.incident_assignments USING btree (rejected_at DESC) WHERE (rejected_at IS NOT NULL);


--
-- Name: idx_audit_logs_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_entity ON public.audit_logs USING btree (entity_type, entity_id, created_at DESC);


--
-- Name: idx_audit_logs_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user ON public.audit_logs USING btree (user_id, created_at DESC);


--
-- Name: idx_checklist_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_checklist_type ON public.incident_type_checklist_items USING btree (incident_type_id, is_active, sort_order);


--
-- Name: idx_department_types_type_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_department_types_type_active ON public.department_incident_types USING btree (incident_type_id, department_id) WHERE (is_active = true);


--
-- Name: idx_departments_location_gist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departments_location_gist ON public.departments USING gist (location);


--
-- Name: idx_device_tokens_user_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_device_tokens_user_active ON public.device_tokens USING btree (user_id) WHERE (is_active = true);


--
-- Name: idx_emergency_contacts_active_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_emergency_contacts_active_order ON public.emergency_contacts USING btree (is_active, sort_order);


--
-- Name: idx_emergency_contacts_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_emergency_contacts_category ON public.emergency_contacts USING btree (category);


--
-- Name: idx_emergency_guides_active_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_emergency_guides_active_order ON public.emergency_guides USING btree (is_active, sort_order);


--
-- Name: idx_feedbacks_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feedbacks_status_created ON public.citizen_feedbacks USING btree (status, created_at DESC);


--
-- Name: idx_feedbacks_upvotes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feedbacks_upvotes ON public.citizen_feedbacks USING btree (upvotes DESC, created_at DESC);


--
-- Name: idx_feedbacks_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_feedbacks_user ON public.citizen_feedbacks USING btree (user_id, created_at DESC);


--
-- Name: idx_incident_media_incident; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_media_incident ON public.incident_media USING btree (incident_id);


--
-- Name: idx_incident_media_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_media_report ON public.incident_media USING btree (report_id) WHERE (report_id IS NOT NULL);


--
-- Name: idx_incident_media_update; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_media_update ON public.incident_media USING btree (update_id) WHERE (update_id IS NOT NULL);


--
-- Name: idx_incident_reports_incident_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_reports_incident_created ON public.incident_reports USING btree (incident_id, created_at);


--
-- Name: idx_incident_reports_location_gist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_reports_location_gist ON public.incident_reports USING gist (reported_location);


--
-- Name: idx_incident_reports_manual_review; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_reports_manual_review ON public.incident_reports USING btree (created_at) WHERE (requires_manual_review = true);


--
-- Name: idx_incident_reports_reporter_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_reports_reporter_created ON public.incident_reports USING btree (reporter_id, created_at DESC);


--
-- Name: idx_incident_updates_incident_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_updates_incident_created ON public.incident_updates USING btree (incident_id, created_at);


--
-- Name: idx_incident_updates_progress; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incident_updates_progress ON public.incident_updates USING btree (incident_id, created_at DESC);


--
-- Name: idx_incidents_location_gist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidents_location_gist ON public.incidents USING gist (location);


--
-- Name: idx_incidents_open_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidents_open_priority ON public.incidents USING btree (priority_score DESC NULLS LAST, created_at) WHERE ((status)::text <> ALL ((ARRAY['RESOLVED'::character varying, 'REJECTED'::character varying, 'CANCELLED'::character varying])::text[]));


--
-- Name: idx_incidents_pending_verification; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidents_pending_verification ON public.incidents USING btree (updated_at) WHERE ((status)::text = 'PENDING_VERIFICATION'::text);


--
-- Name: idx_incidents_status_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidents_status_priority ON public.incidents USING btree (status, priority_score DESC NULLS LAST, created_at);


--
-- Name: idx_incidents_type_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_incidents_type_created ON public.incidents USING btree (incident_type_id, created_at DESC);


--
-- Name: idx_interested_area_center_gist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_interested_area_center_gist ON public.user_interested_areas USING gist (center);


--
-- Name: idx_interested_area_user_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_interested_area_user_active ON public.user_interested_areas USING btree (user_id, is_active);


--
-- Name: idx_notifications_push_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_push_queue ON public.notifications USING btree (created_at) WHERE ((push_status)::text = ANY ((ARRAY['PENDING'::character varying, 'FAILED'::character varying])::text[]));


--
-- Name: idx_notifications_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_created ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: idx_notifications_user_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_unread ON public.notifications USING btree (user_id, created_at DESC) WHERE (is_read = false);


--
-- Name: idx_refresh_tokens_user_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_user_active ON public.refresh_tokens USING btree (user_id, expires_at) WHERE (revoked_at IS NULL);


--
-- Name: idx_users_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_department ON public.users USING btree (department_id) WHERE (department_id IS NOT NULL);


--
-- Name: uq_algorithm_configs_active_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_algorithm_configs_active_key ON public.algorithm_configs USING btree (config_key) WHERE (is_active = true);


--
-- Name: uq_incident_assignments_current; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_incident_assignments_current ON public.incident_assignments USING btree (incident_id) WHERE (ended_at IS NULL);


--
-- Name: uq_interested_area_user_name_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_interested_area_user_name_active ON public.user_interested_areas USING btree (user_id, lower((name)::text)) WHERE (is_active = true);


--
-- Name: uq_notifications_user_event; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_notifications_user_event ON public.notifications USING btree (user_id, ((data ->> 'event_key'::text))) WHERE (data ? 'event_key'::text);


--
-- Name: algorithm_configs trg_algorithm_configs_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_algorithm_configs_updated_at BEFORE UPDATE ON public.algorithm_configs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: areas trg_areas_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_areas_updated_at BEFORE UPDATE ON public.areas FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: department_incident_types trg_department_types_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_department_types_updated_at BEFORE UPDATE ON public.department_incident_types FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: departments trg_departments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_departments_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: device_tokens trg_device_tokens_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_device_tokens_updated_at BEFORE UPDATE ON public.device_tokens FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: incident_types trg_incident_types_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_incident_types_updated_at BEFORE UPDATE ON public.incident_types FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: incidents trg_incidents_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_incidents_updated_at BEFORE UPDATE ON public.incidents FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: ai_feedbacks ai_feedbacks_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_feedbacks
    ADD CONSTRAINT ai_feedbacks_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: ai_feedbacks ai_feedbacks_confirmed_incident_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_feedbacks
    ADD CONSTRAINT ai_feedbacks_confirmed_incident_type_id_fkey FOREIGN KEY (confirmed_incident_type_id) REFERENCES public.incident_types(id);


--
-- Name: ai_feedbacks ai_feedbacks_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_feedbacks
    ADD CONSTRAINT ai_feedbacks_report_id_fkey FOREIGN KEY (report_id) REFERENCES public.incident_reports(id) ON DELETE CASCADE;


--
-- Name: citizen_feedback_upvotes citizen_feedback_upvotes_feedback_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citizen_feedback_upvotes
    ADD CONSTRAINT citizen_feedback_upvotes_feedback_id_fkey FOREIGN KEY (feedback_id) REFERENCES public.citizen_feedbacks(id) ON DELETE CASCADE;


--
-- Name: citizen_feedback_upvotes citizen_feedback_upvotes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citizen_feedback_upvotes
    ADD CONSTRAINT citizen_feedback_upvotes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: citizen_feedbacks citizen_feedbacks_responded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citizen_feedbacks
    ADD CONSTRAINT citizen_feedbacks_responded_by_fkey FOREIGN KEY (responded_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: citizen_feedbacks citizen_feedbacks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.citizen_feedbacks
    ADD CONSTRAINT citizen_feedbacks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: algorithm_configs fk_algorithm_configs_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.algorithm_configs
    ADD CONSTRAINT fk_algorithm_configs_user FOREIGN KEY (updated_by) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: areas fk_areas_department; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT fk_areas_department FOREIGN KEY (department_id) REFERENCES public.departments(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_assignments fk_assignments_acceptor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_assignments
    ADD CONSTRAINT fk_assignments_acceptor FOREIGN KEY (accepted_by) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: incident_assignments fk_assignments_assigner; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_assignments
    ADD CONSTRAINT fk_assignments_assigner FOREIGN KEY (assigned_by) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: incident_assignments fk_assignments_department; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_assignments
    ADD CONSTRAINT fk_assignments_department FOREIGN KEY (department_id) REFERENCES public.departments(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_assignments fk_assignments_incident; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_assignments
    ADD CONSTRAINT fk_assignments_incident FOREIGN KEY (incident_id) REFERENCES public.incidents(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: audit_logs fk_audit_logs_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: department_incident_types fk_department_incident_types_department; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_incident_types
    ADD CONSTRAINT fk_department_incident_types_department FOREIGN KEY (department_id) REFERENCES public.departments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: department_incident_types fk_department_incident_types_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department_incident_types
    ADD CONSTRAINT fk_department_incident_types_type FOREIGN KEY (incident_type_id) REFERENCES public.incident_types(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: device_tokens fk_device_tokens_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT fk_device_tokens_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: incident_media fk_incident_media_incident; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_media
    ADD CONSTRAINT fk_incident_media_incident FOREIGN KEY (incident_id) REFERENCES public.incidents(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_media fk_incident_media_report; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_media
    ADD CONSTRAINT fk_incident_media_report FOREIGN KEY (report_id) REFERENCES public.incident_reports(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_media fk_incident_media_update; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_media
    ADD CONSTRAINT fk_incident_media_update FOREIGN KEY (update_id) REFERENCES public.incident_updates(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_media fk_incident_media_uploader; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_media
    ADD CONSTRAINT fk_incident_media_uploader FOREIGN KEY (uploaded_by) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_reports fk_incident_reports_incident; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_reports
    ADD CONSTRAINT fk_incident_reports_incident FOREIGN KEY (incident_id) REFERENCES public.incidents(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_reports fk_incident_reports_reporter; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_reports
    ADD CONSTRAINT fk_incident_reports_reporter FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_updates fk_incident_updates_incident; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_updates
    ADD CONSTRAINT fk_incident_updates_incident FOREIGN KEY (incident_id) REFERENCES public.incidents(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_updates fk_incident_updates_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_updates
    ADD CONSTRAINT fk_incident_updates_user FOREIGN KEY (updated_by) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incidents fk_incidents_incident_type; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT fk_incidents_incident_type FOREIGN KEY (incident_type_id) REFERENCES public.incident_types(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: user_interested_areas fk_interested_area_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_interested_areas
    ADD CONSTRAINT fk_interested_area_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications fk_notifications_incident; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_incident FOREIGN KEY (incident_id) REFERENCES public.incidents(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: notifications fk_notifications_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: refresh_tokens fk_refresh_tokens_replacement; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT fk_refresh_tokens_replacement FOREIGN KEY (replaced_by_id) REFERENCES public.refresh_tokens(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: refresh_tokens fk_refresh_tokens_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users fk_users_department; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_users_department FOREIGN KEY (department_id) REFERENCES public.departments(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: incident_assignments incident_assignments_assigned_officer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_assignments
    ADD CONSTRAINT incident_assignments_assigned_officer_id_fkey FOREIGN KEY (assigned_officer_id) REFERENCES public.users(id);


--
-- Name: incident_assignments incident_assignments_rejected_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_assignments
    ADD CONSTRAINT incident_assignments_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.users(id);


--
-- Name: incident_checklist_results incident_checklist_results_checklist_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_checklist_results
    ADD CONSTRAINT incident_checklist_results_checklist_item_id_fkey FOREIGN KEY (checklist_item_id) REFERENCES public.incident_type_checklist_items(id);


--
-- Name: incident_checklist_results incident_checklist_results_completed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_checklist_results
    ADD CONSTRAINT incident_checklist_results_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES public.users(id);


--
-- Name: incident_checklist_results incident_checklist_results_incident_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_checklist_results
    ADD CONSTRAINT incident_checklist_results_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES public.incidents(id);


--
-- Name: incident_type_checklist_items incident_type_checklist_items_incident_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incident_type_checklist_items
    ADD CONSTRAINT incident_type_checklist_items_incident_type_id_fkey FOREIGN KEY (incident_type_id) REFERENCES public.incident_types(id);


--
-- Name: incidents incidents_ai_suggested_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_ai_suggested_department_id_fkey FOREIGN KEY (ai_suggested_department_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: incidents incidents_ai_suggested_officer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_ai_suggested_officer_id_fkey FOREIGN KEY (ai_suggested_officer_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict 9JFUnTut91brATUey3H8isyz7ychr3cKuPtIY43t5AHa0bMI3iJBNOmAfiB9Jpc

