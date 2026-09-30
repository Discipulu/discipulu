import type { Meta, StoryObj } from "@storybook/nextjs-vite";

import { Label } from "./label";

const meta = {
  title: "UI/Label",
  component: Label,
  args: {
    children: "E-mail",
  },
} satisfies Meta<typeof Label>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};
