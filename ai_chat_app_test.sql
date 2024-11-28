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
    amount integer NOT NULL,
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

