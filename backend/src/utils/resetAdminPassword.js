const path = require('path');
const readline = require('readline');
const crypto = require('crypto');

require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

if (process.env.NODE_ENV === 'test') {
  console.error('Refusing to run with NODE_ENV=test.');
  process.exitCode = 1;
  return;
}

const sequelize = require('../config/database');
const { User } = require('../models');

const readHidden = (prompt) => new Promise((resolve, reject) => {
  const input = process.stdin;
  const output = process.stdout;
  const readlineInterface = readline.createInterface({ input, output });

  output.write(prompt);

  if (!input.isTTY || typeof input.setRawMode !== 'function') {
    readlineInterface.close();
    reject(new Error('A TTY is required so the temporary password is not echoed.'));
    return;
  }

  let value = '';
  input.setRawMode(true);
  input.resume();

  const onData = (chunk) => {
    const character = chunk.toString('utf8');

    if (character === '\u0003') {
      cleanup();
      reject(new Error('Password entry cancelled.'));
    } else if (character === '\r' || character === '\n') {
      cleanup();
      output.write('\n');
      resolve(value);
    } else if (character === '\u007f' || character === '\b') {
      value = value.slice(0, -1);
    } else if (character.length === 1) {
      value += character;
    }
  };

  const cleanup = () => {
    input.removeListener('data', onData);
    input.setRawMode(false);
    input.pause();
    readlineInterface.close();
  };

  input.on('data', onData);
});

const generateTemporaryPassword = () => crypto.randomBytes(18).toString('base64url');

const generateSimplePassword = () => {
  const number = crypto.randomInt(1000, 10000);
  return `Billboard-${number}!`;
};

const verifyLogin = async (temporaryPassword) => {
  const response = await fetch('http://localhost:3000/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'kelly@gmail.com', password: temporaryPassword })
  });
  const result = await response.json();

  if (!response.ok || !result.success || result.data?.user?.role !== 'ADMIN') {
    throw new Error('Login verification failed.');
  }

  console.log('Login verification succeeded for the ADMIN account.');
};

const resetAdminPassword = async () => {
  const generated = process.argv.includes('--generate');
  const simple = process.argv.includes('--simple');
  const verify = process.argv.includes('--verify');
  const temporaryPassword = generated || simple
    ? (simple ? generateSimplePassword() : generateTemporaryPassword())
    : await readHidden('Enter temporary password: ');
  if (!temporaryPassword || temporaryPassword.length < 8) {
    throw new Error('Temporary password must be at least 8 characters long.');
  }

  if (!generated && !simple) {
    const confirmation = await readHidden('Confirm temporary password: ');
    if (temporaryPassword !== confirmation) {
      throw new Error('Passwords do not match.');
    }
  }

  const user = await User.findOne({
    where: {
      userId: 9,
      email: 'kelly@gmail.com'
    }
  });

  if (!user) {
    throw new Error('No user matched both userId 9 and email kelly@gmail.com. No changes were made.');
  }

  if (user.role !== 'ADMIN' || user.accountStatus !== 'ACTIVE') {
    throw new Error('The matched account is not ADMIN and ACTIVE. No changes were made.');
  }

  user.password = temporaryPassword;
  await user.save();
  if (verify) {
    await verifyLogin(temporaryPassword);
  }
  console.log('Temporary password reset successfully for userId 9.');
  if (generated || simple) {
    console.log(`Temporary password: ${temporaryPassword}`);
  }
};

resetAdminPassword()
  .catch((error) => {
    console.error(`Password reset failed: ${error.message}`);
    process.exitCode = 1;
  })
  .finally(async () => {
    await sequelize.close();
  });