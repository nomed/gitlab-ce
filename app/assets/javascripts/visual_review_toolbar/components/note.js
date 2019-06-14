import { NOTE, NOTE_CONTAINER, RED } from './constants';
import { selectById, selectNote } from './utils';

const note = `
  <div id="${NOTE_CONTAINER}">
    <p id="${NOTE}" class="gitlab-message">Hello from the note, friend.</p>
  </div>
`;

const clearNote = inputId => {
  const currentNote = selectNote();
  currentNote.innerText = '';
  currentNote.style.color = '';

  if (inputId) {
    const field = document.getElementById(inputId);
    field.style.borderColor = '';
  }
};

const postError = (message, inputId) => {
  const currentNote = selectNote();
  const field = selectById(inputId);
  field.style.borderColor = RED;
  currentNote.style.color = RED;
  currentNote.innerText = message;
};

export { clearNote, note, postError };
