--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

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
-- Name: ensure_free_plan_model(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ensure_free_plan_model() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.plan = 'Free' THEN
        NEW.selectedmodel = 'gpt-3.5-turbo';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.ensure_free_plan_model() OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: user_account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_account (
    email character varying(255) NOT NULL,
    username character varying(255),
    password_hash text,
    plan character varying(50),
    monthly_cost real DEFAULT 0.0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp without time zone,
    login_attempts integer DEFAULT 0,
    last_attempt_time timestamp without time zone,
    unlock_token character varying(255),
    user_name character varying(255),
    isdarkmode boolean DEFAULT false,
    selectedmodel character varying(255),
    chat_history_max_length integer DEFAULT 1000,
    input_text_length integer DEFAULT 200,
    sortorder character varying(50) DEFAULT 'created_at ASC'::character varying,
    next_process_date timestamp without time zone,
    last_payment_date timestamp without time zone,
    customer_id character varying(255),
    next_process_type character varying(50),
    CONSTRAINT user_account_next_process_type_check CHECK (((next_process_type)::text = ANY ((ARRAY['payment'::character varying, 'cancel'::character varying, 'plan_change'::character varying])::text[])))
);


ALTER TABLE public.user_account OWNER TO postgres;

--
-- Name: user_payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_payment (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    processed_date timestamp without time zone DEFAULT now() NOT NULL,
    plan character varying(50) NOT NULL,
    amount integer,
    next_process_date timestamp without time zone,
    message text,
    transaction_id character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    processed_by character varying(50) DEFAULT 'auto'::character varying NOT NULL
);


ALTER TABLE public.user_payment OWNER TO postgres;

--
-- Name: user_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_payment_id_seq OWNER TO postgres;

--
-- Name: user_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_payment_id_seq OWNED BY public.user_payment.id;


--
-- Name: user_payment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment ALTER COLUMN id SET DEFAULT nextval('public.user_payment_id_seq'::regclass);


--
-- Data for Name: user_account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_account (email, username, password_hash, plan, monthly_cost, created_at, last_login, login_attempts, last_attempt_time, unlock_token, user_name, isdarkmode, selectedmodel, chat_history_max_length, input_text_length, sortorder, next_process_date, last_payment_date, customer_id, next_process_type) FROM stdin;
hiromichi.works@gmail.com	金子弘典	\N	Free	\N	2024-12-13 12:12:25.627462	2024-12-13 18:10:23.419812	0	\N	\N	\N	f	gpt-3.5-turbo	1000	200	created_at ASC	\N	\N	\N	\N
\.


--
-- Data for Name: user_payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_payment (id, email, processed_date, plan, amount, next_process_date, message, transaction_id, created_at, updated_at, processed_by) FROM stdin;
3229	hiromichi.works@gmail.com	2024-12-13 12:12:36.559189	Standard	1950	2024-12-13 12:13:36.528368	有料プラン加入支払い	pi_3QVPIvJg9yO0NmBs0bk8kHDq	2024-12-13 12:12:36.559189	2024-12-13 12:12:36.559189	payment
3230	hiromichi.works@gmail.com	2024-12-13 12:41:03.358931	Standard	1950	\N	定期支払い	pi_3QVPkTJg9yO0NmBs0BoIaoQr	2024-12-13 12:41:03.358931	2024-12-13 12:41:03.358931	auto_subscription
3231	hiromichi.works@gmail.com	2024-12-13 12:44:05.557469	Standard	1950	\N	定期支払い	pi_3QVPnPJg9yO0NmBs0J7ssnT3	2024-12-13 12:44:05.557469	2024-12-13 12:44:05.557469	auto_subscription
3232	hiromichi.works@gmail.com	2024-12-13 12:47:07.798286	Standard	1950	\N	定期支払い	pi_3QVPqLJg9yO0NmBs0Kdcfs9B	2024-12-13 12:47:07.798286	2024-12-13 12:47:07.798286	auto_subscription
3233	hiromichi.works@gmail.com	2024-12-13 12:50:10.085778	Standard	1950	\N	定期支払い	pi_3QVPtHJg9yO0NmBs0pN0ulb5	2024-12-13 12:50:10.085778	2024-12-13 12:50:10.085778	auto_subscription
3234	hiromichi.works@gmail.com	2024-12-13 12:53:12.246558	Standard	0	\N	プラン解約	\N	2024-12-13 12:53:12.246558	2024-12-13 12:53:12.246558	auto_cancellation
3235	hiromichi.works@gmail.com	2024-12-13 17:26:07.974126	Standard	1950	2024-12-13 17:27:07.946594	有料プラン加入支払い	pi_3QVUCKJg9yO0NmBs0znfcFza	2024-12-13 17:26:07.974126	2024-12-13 17:26:07.974126	payment
3236	hiromichi.works@gmail.com	2024-12-13 17:30:19.538223	Standard	1950	\N	定期支払い	pi_3QVUGPJg9yO0NmBs0ip5XuBP	2024-12-13 17:30:19.538223	2024-12-13 17:30:19.538223	auto_subscription
3237	hiromichi.works@gmail.com	2024-12-13 17:33:21.98941	Standard	1950	\N	定期支払い	pi_3QVUJMJg9yO0NmBs1TvJtl91	2024-12-13 17:33:21.98941	2024-12-13 17:33:21.98941	auto_subscription
3238	hiromichi.works@gmail.com	2024-12-13 17:36:24.249687	Standard	0	\N	プラン解約	\N	2024-12-13 17:36:24.249687	2024-12-13 17:36:24.249687	auto_cancellation
\.


--
-- Name: user_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_payment_id_seq', 3238, true);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (email);


--
-- Name: user_payment user_payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment
    ADD CONSTRAINT user_payment_pkey PRIMARY KEY (id);


--
-- Name: idx_user_payment_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_payment_date ON public.user_payment USING btree (processed_date);


--
-- Name: idx_user_payment_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_payment_email ON public.user_payment USING btree (email);


--
-- Name: idx_user_payment_transaction; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_payment_transaction ON public.user_payment USING btree (transaction_id);


--
-- Name: user_account enforce_free_plan_model; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER enforce_free_plan_model BEFORE INSERT OR UPDATE ON public.user_account FOR EACH ROW EXECUTE FUNCTION public.ensure_free_plan_model();


--
-- Name: user_payment update_user_payment_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_user_payment_updated_at BEFORE UPDATE ON public.user_payment FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_payment user_payment_email_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_payment
    ADD CONSTRAINT user_payment_email_fkey FOREIGN KEY (email) REFERENCES public.user_account(email);


--
-- PostgreSQL database dump complete
--

