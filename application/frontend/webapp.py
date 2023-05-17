# Modified from https://github.com/deepset-ai/haystack/blob/main/ui/webapp.py
# commit 1a0197839c6ee0a90e0f562af5edf57a891d473a 
# under  Apache-2.0 license 
###########################################################################################################

import os
import sys
import logging
import random
from pathlib import Path
from json import JSONDecodeError

import pandas as pd
import streamlit as st
from annotated_text import annotation
from markdown import markdown

from ui.utils import haystack_is_ready, query, send_feedback, upload_doc, haystack_version, get_backlink


# Adjust to a question that you would like users to see in the search bar when they load the UI:
DEFAULT_QUESTION_AT_STARTUP = os.getenv("DEFAULT_QUESTION_AT_STARTUP", "How  to protect against DDoS attacks?")
DEFAULT_ANSWER_AT_STARTUP = os.getenv("DEFAULT_ANSWER_AT_STARTUP", "AWS Shield is a managed Distributed Denial of Service (DDoS) protection service that safeguards applications running on AWS. AWS Shield provides always-on detection and automatic inline mitigations that minimize application downtime and latency, so there is no need to engage AWS Support to benefit from DDoS protection")

# Sliders
DEFAULT_DOCS_FROM_RETRIEVER = int(os.getenv("DEFAULT_DOCS_FROM_RETRIEVER", "3"))
DEFAULT_NUMBER_OF_ANSWERS = int(os.getenv("DEFAULT_NUMBER_OF_ANSWERS", "3"))



def set_state_if_absent(key, value):
    if key not in st.session_state:
        st.session_state[key] = value


def main():

    st.set_page_config(page_title="Semantic Search - AWS Docs", page_icon="https://a0.awsstatic.com/libra-css/images/site/fav/favicon.ico")

    # Persistent state
    set_state_if_absent("question", DEFAULT_QUESTION_AT_STARTUP)
    set_state_if_absent("answer", DEFAULT_ANSWER_AT_STARTUP)
    set_state_if_absent("results", None)
    set_state_if_absent("raw_json", None)
    set_state_if_absent("random_question_requested", False)

    # Small callback to reset the interface in case the text of the question changes
    def reset_results(*args):
        st.session_state.answer = None
        st.session_state.results = None
        st.session_state.raw_json = None

    # Title
    st.write("# Semantic Search on AWS Documentation")
    st.markdown(
        """
Ask any question on about the AWS documentation to see if we can find the correct answer to your query!
*Note: do not use keywords, but full-fledged questions.* The demo is not optimized to deal with keyword queries and might misunderstand you.
""",
        unsafe_allow_html=True,
    )

    # Sidebar
    st.sidebar.header("Options")
    
    answer_style = st.sidebar.radio(
     "Answer Style:",
     ('Extractive', 'Generative'),
     index=0,
     on_change=reset_results
    )

    
    top_k_reader = st.sidebar.slider(
        "Max. number of answers",
        min_value=1,
        max_value=10,
        value=DEFAULT_NUMBER_OF_ANSWERS,
        step=1,
        on_change=reset_results,
    )
    top_k_retriever = st.sidebar.slider(
        "Max. number of documents from retriever",
        min_value=1,
        max_value=10,
        value=DEFAULT_DOCS_FROM_RETRIEVER,
        step=1,
        on_change=reset_results,
    )
    debug = st.sidebar.checkbox("Show debug info")


    hs_version = ""
    try:
        hs_version = f" <small>(v{haystack_version(answer_style=answer_style)})</small>"
    except Exception:
        pass

    st.sidebar.markdown(
        f"""
    <style>
        a {{
            text-decoration: none;
        }}
        .haystack-footer {{
            text-align: center;
        }}
        .haystack-footer h4 {{
            margin: 0.1rem;
            padding:0;
        }}
        footer {{
            opacity: 0;
        }}
    </style>
    <div class="haystack-footer">
        <hr />
        <h4>Built with <a href="https://www.deepset.ai/haystack">Haystack</a>{hs_version}</h4>
        <p>Get it on <a href="https://github.com/deepset-ai/haystack/">GitHub</a> &nbsp;&nbsp; - &nbsp;&nbsp; Read the <a href="https://haystack.deepset.ai/overview/intro">Docs</a></p>
    </div>
    """,
        unsafe_allow_html=True,
    )

    # Search bar
    question = st.text_input("", value=st.session_state.question, max_chars=100, on_change=reset_results)
    col1, col2 = st.columns(2)
    col1.markdown("<style>.stButton button {width:100%;}</style>", unsafe_allow_html=True)
    col2.markdown("<style>.stButton button {width:100%;}</style>", unsafe_allow_html=True)

    # Run button
    run_pressed = col1.button("Run")


    example_questions = [
        "What is Amazon SageMaker?",
        "Why is it a best practice to use multiple availability zones (AZs)?",
        "How to protect against DDoS on AWS?"
    ]

    # Get next random question from the CSV
    if col2.button("Random question"):
        reset_results()
        st.session_state.question = random.choice(example_questions)
        st.session_state.answer = ""
        st.session_state.random_question_requested = True
        # Re-runs the script setting the random question as the textbox value
        # Unfortunately necessary as the Random Question button is _below_ the textbox
        raise st.scriptrunner.script_runner.RerunException(st.scriptrunner.script_requests.RerunData(None))
    st.session_state.random_question_requested = False

    run_query = (
        run_pressed or question != st.session_state.question
    ) and not st.session_state.random_question_requested

    # Check the connection
    with st.spinner("⌛️ &nbsp;&nbsp; Backend is starting..."):
        if not haystack_is_ready(answer_style=answer_style):
            st.error("🚫 &nbsp;&nbsp; Connection Error. Is the backend running?")
            run_query = False
            reset_results()

    # Get results for query
    if run_query and question:
        reset_results()
        st.session_state.question = question

        with st.spinner(
            "🧠 &nbsp;&nbsp; Performing neural search on documents... \n "
            "Do you want to optimize speed or accuracy? \n"
            "Check out the docs: https://haystack.deepset.ai/usage/optimization "
        ):
            try:
                st.session_state.results, st.session_state.raw_json = query(
                    question, top_k_reader=top_k_reader, top_k_retriever=top_k_retriever, answer_style=answer_style, debug=debug
                )
            except JSONDecodeError as je:
                st.error("👓 &nbsp;&nbsp; An error occurred reading the results. Is the document store working?")
                return
            except Exception as e:
                logging.exception(e)
                if "The server is busy processing requests" in str(e) or "503" in str(e):
                    st.error("🧑‍🌾 &nbsp;&nbsp; All our workers are busy! Try again later.")
                else:
                    st.error("🐞 &nbsp;&nbsp; An error occurred during the request.")
                return

    if st.session_state.results:

        st.write("## Results:")

        for count, result in enumerate(st.session_state.results):
            if result["answer"]:
                answer, context = result["answer"], result["context"]
                start_idx = context.find(answer)
                end_idx = start_idx + len(answer)
                # Hack due to this bug: https://github.com/streamlit/streamlit/issues/3190
                st.write(
                    markdown(context[:start_idx] + str(annotation(answer, "ANSWER", "#8ef")) + context[end_idx:]),
                    unsafe_allow_html=True,
                )
                source = ""
                url, title = get_backlink(result)
                if url and title:
                    source = f"[{result['document']['meta']['title']}]({result['document']['meta']['url']})"
                else:
                    source = f"{result['source']}"
                st.markdown(f"**Relevance:** {result['relevance']} -  **Source:** {source}")

            else:
                st.info(
                    "🤔 &nbsp;&nbsp; Haystack is unsure whether any of the documents contain an answer to your question. Try to reformulate it!"
                )
                st.write("**Relevance:** ", result["relevance"])

            st.write("___")
        if debug:
            st.subheader("REST API JSON response")
            st.write(st.session_state.raw_json)

main()