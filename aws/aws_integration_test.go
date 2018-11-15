// +build integration

package aws

import (
	"fmt"
	"io/ioutil"
	"os"
	"testing"

	"github.com/VirtusLab/crypt/crypto"
	"github.com/sirupsen/logrus"
	"github.com/sirupsen/logrus/hooks/test"
	"github.com/stretchr/testify/assert"
)

func TestEncryptDecryptWithAWS(t *testing.T) {
	type TestCase struct {
		name    string
		f       func(TestCase)
		logHook *test.Hook
	}

	// configuration from config.env
	key := os.Getenv("AWS_KEY")
	region := os.Getenv("AWS_REGION")

	when := func(crypt *crypto.Crypt, inputPath string) (string, error) {
		defer os.Remove(inputPath + ".encrypted") // clean up
		defer os.Remove(inputPath + ".decrypted") // clean up

		err := crypt.EncryptFile(inputPath, inputPath+".encrypted")
		if err != nil {
			return "", err
		}

		err = crypt.DecryptFile(inputPath+".encrypted", inputPath+".decrypted")
		if err != nil {
			return "", err
		}

		result, err := ioutil.ReadFile(inputPath + ".decrypted")
		if err != nil {
			return "", err
		}

		return string(result), nil
	}

	cases := []TestCase{
		{
			name: "encrypt decrypt file",
			f: func(tc TestCase) {
				amazon := New(key, region)
				crypt := crypto.New(amazon)

				inputFile := "test.txt"
				expected := "top secret token"
				err := ioutil.WriteFile(inputFile, []byte(expected), 0644)
				if err != nil {
					t.Fatal("Can't write plaintext file", err)
				}
				defer os.Remove(inputFile)

				actual, err := when(crypt, inputFile)

				assert.Equal(t, expected, string(actual))
			},
		},
	}

	logrus.SetLevel(logrus.DebugLevel)
	hook := test.NewGlobal()

	for i, c := range cases {
		c.logHook = hook
		t.Run(fmt.Sprintf("[%d] %s", i, c.name), func(t *testing.T) { c.f(c) })
		hook.Reset()
	}
}
