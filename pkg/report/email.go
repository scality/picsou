package report

import (
	"bytes"
	"fmt"
	"html/template"
	"net/smtp"
)

type TemplateData struct {
	Name string
	URL string
}

type Template struct {
	filename string
	data interface{}
}

//Request struct
type Request struct {
	from    string
	to      []string
	subject string
	body    string
	template *Template
}

func NewRequest(to []string, subject, body, templatePath string, templateData *TemplateData) *Request {
	return &Request{
		to:      to,
		subject: subject,
		body:    body,
		template: &Template{
			filename: templatePath,
			data: templateData,
		},
	}
}

func (r *Request) SendEmail() *Request {
	from := "From: maxime.vaude@gmail.com\r\n"
	to := "To: " + r.to[0] + "\r\n"
	mime := "MIME-version: 1.0;\nContent-Type: text/html; charset=\"UTF-8\";\r\n"
	subject := "Subject: " + r.subject + "\r\n\r\n"
	msg := []byte(from + to + mime + subject + "\n" + r.body + "\r\n")
	addr := "smtp.gmail.com:587"

	if err := smtp.SendMail(addr, auth, "maxime.vaude@gmail.com", r.to, msg); err != nil {
		return nil
	}
	return r
}

func (r *Request) ParseTemplate() *Request {
	t, err := template.ParseFiles(r.template.filename)
	if err != nil {
		return nil
	}
	buf := new(bytes.Buffer)
	if err = t.Execute(buf, r.template.data); err != nil {
		return nil
	}
	r.body = buf.String()
	return r
}
